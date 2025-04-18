//
//  InsightDetailCaveViewController.swift
//  Growthook
//
//  Created by KYUBO A. SHIM on 1/15/24.
//

import UIKit

import RxCocoa
import RxSwift

protocol CaveDismissDelegate: AnyObject {
    func dismissPresentingView()
}

final class InsightDetailCaveViewController: BaseViewController {

    // MARK: - Properties
    weak var delegate: CaveDismissDelegate?
    private let disposeBag = DisposeBag()
    private var viewModel: InsightsDetailViewModel
    private var selectedCaveCache: InsightCaveModel?
    
    // MARK: - UI Properties
    private let caveTableView = UITableView()
    private let selectCaveButton = UIButton()
    
    // MARK: - Life Cycles
    init(viewModel: InsightsDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.inputs.reloadSeedData()
    }
    
    override func bindViewModel() {
    // MARK: - Tap Actions
        caveTableView.rx.modelSelected(InsightCaveModel.self)
            .bind { [weak self] data in
                guard let self else { return }
                self.selectedCaveCache = .init(caveId: data.caveId, caveTitle: data.caveTitle)
            }
            .disposed(by: disposeBag)
        
        selectCaveButton.rx.tap
            .bind { [weak self] in
                guard let self else { return }
                if selectedCaveCache != nil {
                    guard let selectedCaveCache else { return }
                    self.viewModel.inputs.moveSeedToOtherCave(of: selectedCaveCache)
                    self.delegate?.dismissPresentingView()
                }
                self.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
    // MARK: - Bind UI With Data
        viewModel.outputs.caveData
            .bind(to: caveTableView.rx.items(cellIdentifier: InsightSelectCaveTableViewCell.className, cellType: InsightSelectCaveTableViewCell.self)) { row, data, cell in
                let caveModelData = InsightCaveModel(caveId: data.caveId, caveTitle: data.caveTitle)
                cell.configure(with: caveModelData)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Register Cell
    override func setRegister() {
        caveTableView.register(InsightSelectCaveTableViewCell.self, forCellReuseIdentifier: InsightSelectCaveTableViewCell.className)
    }
    
    // MARK: - Styles
    override func setStyles() {
        view.backgroundColor = .gray400
        
        caveTableView.do {
            $0.rowHeight = 54
            $0.separatorColor = .gray200
            $0.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            $0.backgroundColor = .gray400
            $0.allowsMultipleSelection = false
            $0.showsVerticalScrollIndicator = true
        }
        
        selectCaveButton.do {
            $0.layer.cornerRadius = 10
            $0.setTitle("선택", for: .normal)
            $0.backgroundColor = .green400
            $0.setTitleColor(.white000, for: .normal)
            $0.titleLabel?.font = .fontGuide(.body1_bold)
        }
    }
    
    // MARK: - Layout
    override func setLayout() {
        view.addSubviews(caveTableView, selectCaveButton)
        
        caveTableView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(50)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(250)
        }
        
        selectCaveButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(50)
            $0.horizontalEdges.equalToSuperview().inset(18)
            $0.height.equalTo(50)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
