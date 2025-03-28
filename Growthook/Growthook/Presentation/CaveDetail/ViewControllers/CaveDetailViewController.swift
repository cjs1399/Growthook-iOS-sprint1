//
//  CaveDetailViewController.swift
//  Growthook
//
//  Created by KJ on 12/16/23.
//

import UIKit

import Moya
import SnapKit
import Then
import RxCocoa
import RxSwift

final class CaveDetailViewController: BaseViewController {
    
    // MARK: - UI Components
    
    private let caveDetailView = CaveDetailView()
    private lazy var unLockInsightAlertView = UnLockInsightAlertView()
    private lazy var unLockCaveAlertView = UnLockCaveAlertView()
    lazy var longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    private lazy var insightListEmptyView = InsightListEmptyView()
    
    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        if !isFirstLaunched {
            viewModel.getCaveSeedList(caveId: caveId)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Properties
    
    private let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    private var lockSeedId: Int?
    private var caveId: Int
    private var lockActionPlan: Bool?
    private var isFirstLaunched: Bool = true
    
    // MARK: - Initializer

    init(viewModel: HomeViewModel, caveId: Int){
        self.viewModel = viewModel
        self.caveId = caveId
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGesture()
        setNotification()
        isFirstLaunched = false
    }
    
    override func bindViewModel() {
        
        viewModel.inputs.caveDetail(caveId: caveId)
        
        viewModel.outputs.caveDetail
            .bind(onNext: { [weak self] model in
                guard let self = self else { return }
                caveDetailView.caveDescriptionView.configureView(model)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.caveInsightList
            .do(onNext: { [weak self] list in
                guard list.isEmpty else { return }
                self?.caveDetailView.emptyInsightView.isHidden = false
                self?.caveDetailView.insightListView.isHidden = true
                self?.insightListEmptyView.isHidden = true
            })
            .map { [weak self] list in
                guard let type = self?.caveDetailView.insightListView.scrapType else { return list }
                let scrapType = type ? list.filter { $0.isScraped } : list
                if scrapType.count == 0 {
                    self?.insightListEmptyView.isHidden = false
                } else {
                    self?.insightListEmptyView.isHidden = true
                }
                return scrapType
            }
            .bind(to: caveDetailView.insightListView.insightCollectionView.rx.items(cellIdentifier: InsightListCollectionViewCell.className, cellType: InsightListCollectionViewCell.self)) { (index, model, cell) in
                self.caveDetailView.emptyInsightView.isHidden = true
                self.caveDetailView.insightListView.isHidden = false
                self.insightListEmptyView.isHidden = true
                cell.configureCell(model)
                cell.setCellStyle()
                cell.scrapButtonTapHandler = { [weak self] in
                    guard let self else { return }
                    if !cell.isScrapButtonTapped {
                        self.view.showScrapToast(message: I18N.Component.ToastMessage.scrap)
                    }
                    cell.isScrapButtonTapped.toggle()
                    self.viewModel.inputs.insightScrap(seedId: model.seedId, index: index)
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.outputs.caveInsightAllCount
            .subscribe(onNext: { [weak self] count in
                self?.caveDetailView.insightListView.seedTitleLabel.text = "\(count)\(I18N.Home.seedsCollected)"
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.insightLongTap
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.caveDetailView.addSeedButton.isHidden = true
                self.makeVibrate()
                self.presentToHalfModalViewController(indexPath)
                if let cell = caveDetailView.insightListView.insightCollectionView.cellForItem(at: indexPath) as? InsightListCollectionViewCell {
                    cell.selectedCell()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.insightBackground
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.caveDetailView.addSeedButton.isHidden = false
                if let cell = caveDetailView.insightListView.insightCollectionView.cellForItem(at: indexPath) as? InsightListCollectionViewCell {
                    cell.unSelectedCell()
                }
            })
            .disposed(by: disposeBag)
        
        caveDetailView.insightListView.insightCollectionView.rx.itemSelected
            .subscribe(onNext: { index in
                print(index)
                self.pushToInsightDetail(at: index)
            })
            .disposed(by: disposeBag)
        
        unLockInsightAlertView.useButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let seedId = self?.lockSeedId else { return }
                if self?.viewModel.ssukCount.value.gatheredSsuk == 0 {
                    self?.unLockInsightAlertView.removeFromSuperview()
                    self?.view.showToastWithRed(message: "쑥이 없어 잠금을 해제할 수 없어요")
                } else {
                    self?.viewModel.inputs.unLockSeedAlertInCave(seedId: seedId)
                }
            })
            .disposed(by: disposeBag)
        
        unLockInsightAlertView.giveUpButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.unLockInsightAlertView.removeFromSuperview()
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.unLockSeedInCave
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.unLockInsightAlertView.removeFromSuperview()
                guard let actionPlan = self.lockActionPlan else { return }
                guard let seedId = self.lockSeedId else { return }
                let vc = InsightsDetailViewController(hasAnyActionPlan: actionPlan, seedId: seedId)
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        caveDetailView.insightListView.scrapButton.rx.tap
            .subscribe(onNext: { [weak self] in
                if let type = self?.caveDetailView.insightListView.scrapType {
                    guard let caveId = self?.caveId else { return }
                    self?.viewModel.inputs.caveOnlyScrapInsight(caveId: caveId)
                    self?.scrapTypeSetting(type)
                }
            })
            .disposed(by: disposeBag)
        
        caveDetailView.caveDescriptionView.lockButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addUnLockCaveAlert()
            })
            .disposed(by: disposeBag)
        
        unLockCaveAlertView.checkButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.unLockCaveAlertView.removeFromSuperview()
                guard let actionPlan = self.lockActionPlan else { return }
                guard let seedId = self.lockSeedId else { return }
                let vc = InsightsDetailViewController(hasAnyActionPlan: actionPlan, seedId: seedId)
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        caveDetailView.addSeedButton.rx.tap
            .bind { [weak self] in
                let vc = CreatingNewInsightsViewController()
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        caveDetailView.navigationView.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.backToHomeVC()
            })
            .disposed(by: disposeBag)
        
        caveDetailView.navigationView.menuButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentToMenuVC()
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.pushToChangeCave
            .subscribe(onNext: { [weak self] in
                guard let caveId = self?.caveId else { return }
                guard let viewModel = self?.viewModel else { return }
                let vc = ChangeCaveViewController(caveId: caveId, homeViewModel: viewModel)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.ssukCount
            .subscribe(onNext: { [weak self] model in
                self?.unLockInsightAlertView.mugwortCount.text = "\(model.gatheredSsuk)"
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - UI Components Property
    
    override func setStyles() {
        
        self.view.backgroundColor = .gray900
        
        insightListEmptyView.do {
            $0.isHidden = true
        }
    }
    
    // MARK: - Layout Helper
    
    override func setLayout() {
        
        self.view.addSubviews(caveDetailView, insightListEmptyView)
        
        caveDetailView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        insightListEmptyView.snp.makeConstraints {
            $0.top.equalTo(caveDetailView.insightListView.scrapButton).offset(124)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(165)
            $0.height.equalTo(180)
        }
    }
    
    // MARK: - Methods
    
    override func setDelegates() {
        longPressGesture.delegate = self
    }
    
    override func setRegister() {
        caveDetailView.insightListView.insightCollectionView.register(InsightListCollectionViewCell.self, forCellWithReuseIdentifier: InsightListCollectionViewCell.className)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CaveDetailViewController {
    
    // MARK: - Methods
    
    private func addGesture() {
        caveDetailView.insightListView.insightCollectionView.addGestureRecognizer(longPressGesture)
    }
    
    private func setNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearNotification(_:)),
            name: Notification.Name(I18N.Component.Identifier.deSelectNoti),
            object: nil)
    }
    
    private func pushToInsightDetail(at indexPath: IndexPath) {
        caveDetailView.insightListView.insightCollectionView.deselectItem(at: indexPath, animated: false)
        if let cell = caveDetailView.insightListView.insightCollectionView.cellForItem(at: indexPath) as? InsightListCollectionViewCell {
            if cell.isLock {
                view.addSubview(unLockInsightAlertView)
                unLockInsightAlertView.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }
                self.lockSeedId = cell.seedId
                self.lockActionPlan = cell.hasActionPlan
            } else {
                let vc = InsightsDetailViewController(hasAnyActionPlan: cell.hasActionPlan, seedId: cell.seedId)
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    private func scrapTypeSetting(_ type: Bool) {
        let newType = type ? false : true
        if newType {
            caveDetailView.insightListView.scrapButton.setImage(ImageLiterals.Scrap.btn_scrap_active, for: .normal)
        } else {
            caveDetailView.insightListView.scrapButton.setImage(ImageLiterals.Scrap.btn_scrap_default, for: .normal)
        }
        caveDetailView.insightListView.scrapType = newType
    }
    
    func updateInsightList() {
        if let selectedItems = caveDetailView.insightListView.insightCollectionView.indexPathsForSelectedItems {
            for indexPath in selectedItems {
                caveDetailView.insightListView.insightCollectionView.deselectItem(at: indexPath, animated: false)
            }
        }
        caveDetailView.insightListView.insightCollectionView.reloadData()
    }
    
    func presentToHalfModalViewController(_ indexPath: IndexPath) {
        let insightTapVC = InsightTapBottomSheet(viewModel: viewModel)
        insightTapVC.modalPresentationStyle = .overFullScreen
        insightTapVC.indexPath = indexPath
        present(insightTapVC, animated: true)
    }
    
    private func addUnLockCaveAlert() {
        view.addSubview(unLockCaveAlertView)
        unLockCaveAlertView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func backToHomeVC() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func presentToMenuVC() {
        let menuVC = UINavigationController(rootViewController: CaveDetailMenuBottomSheet(viewModel: viewModel, caveId: caveId))
        menuVC.modalPresentationStyle = .pageSheet
        let customDetentIdentifier = UISheetPresentationController.Detent.Identifier(I18N.Component.Identifier.customDetent)
        let customDetent = UISheetPresentationController.Detent.custom(identifier: customDetentIdentifier) { (_) in
            return SizeLiterals.Screen.screenHeight * 165 / 812
        }
        
        if let sheet = menuVC.sheetPresentationController {
            sheet.detents = [customDetent]
            sheet.preferredCornerRadius = 10
            sheet.prefersGrabberVisible = true
            sheet.delegate = self
            sheet.delegate = menuVC as? any UISheetPresentationControllerDelegate
        }
        
        present(menuVC, animated: true)
    }
    
    // MARK: - @objc Methods
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        if gesture.state == .began {
            // 꾹 눌림이 시작될 때 실행할 코드
            if let indexPath = caveDetailView.insightListView.insightCollectionView.indexPathForItem(at: location) {
                if let cell = caveDetailView.insightListView.insightCollectionView.cellForItem(at: indexPath) as? InsightListCollectionViewCell {
                    if cell.isLock {
                        return
                    } else {
                        viewModel.inputs.handleLongPress(at: indexPath)
                    }
                }
            }
        }
    }
    
    @objc func clearNotification(_ notification: Notification) {
        updateInsightList()
        caveDetailView.addSeedButton.isHidden = false
        if let info = notification.userInfo?[I18N.Component.Identifier.type] as? ClearInsightType {
            switch info {
            case .move:
                view.showToast(message: I18N.Component.ToastMessage.moveInsight)
            case .delete:
                view.showToast(message: I18N.Component.ToastMessage.removeInsight)
            case .none:
                return
            case .deleteCave:
                view.showToast(message: I18N.Component.ToastMessage.removeCave)
            }
        }
    }
}

extension CaveDetailViewController: UIGestureRecognizerDelegate {}

extension CaveDetailViewController: UISheetPresentationControllerDelegate {}
