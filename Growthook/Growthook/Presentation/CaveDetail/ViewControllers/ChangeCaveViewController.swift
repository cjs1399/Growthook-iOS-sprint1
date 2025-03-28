//
//  CaveChangeViewController.swift
//  Growthook
//
//  Created by KJ on 1/14/24.
//

import UIKit

import Moya
import SnapKit
import Then
import RxCocoa
import RxSwift

final class ChangeCaveViewController: BaseViewController {
    
    // MARK: - UI Components
    
    private let changeCaveView = ChangeCaveView()
    private let viewModel = ChangeCaveViewModel()
    private let disposeBag = DisposeBag()
    private let homeViewModel: HomeViewModel
    
    // MARK: - Properties
    
    private let caveId: Int?
    
    // MARK: - Initializer

    init(caveId: Int, homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        self.caveId = caveId
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
    }
    
    override func bindViewModel() {
        changeCaveView.nameTextField.textFieldBlock.rx.text
            .orEmpty
            .distinctUntilChanged()
            .bind { [weak self] value in
                guard let self else { return }
                self.viewModel.inputs.setName(value: value)
            }
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            changeCaveView.nameTextField.textFieldBlock.rxEditingAction,
            changeCaveView.nameTextField.textFieldBlock.rx.text
                .distinctUntilChanged()
        )
        .observe(on: MainScheduler.asyncInstance)
        .bind { [weak self] event, text in
            guard let self else { return }
            let textField = self.changeCaveView.nameTextField
            switch event {
            case .editingDidBegin:
                textField.textFieldBlock.focusWhenDidBeginEditing()
            case .editingDidEnd:
                textField.textFieldBlock.unfocusWhenDidEndEditing()
            default:
                break
            }
        }
        .disposed(by: disposeBag)
        
        changeCaveView.nameTextField.textFieldBlock.rx.controlEvent([.editingDidEndOnExit])
            .bind { [weak self] in
                guard let self else { return }
                self.setNextTextView()
            }
            .disposed(by: disposeBag)
        
        changeCaveView.introduceTextView.textViewBlock.rx.text
            .orEmpty
            .distinctUntilChanged()
            .bind { [weak self] value in
                guard let self else { return }
                self.viewModel.inputs.setIntroduce(value: value)
            }
            .disposed(by: disposeBag)
        
        viewModel.outputs.isValid
            .map { $0 ? true : false }
            .bind(to: changeCaveView.navigationBar.rx.completionEnableStatus)
            .disposed(by: disposeBag)
        
        changeCaveView.navigationBar.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.popToCaveDetailVC()
            })
            .disposed(by: disposeBag)
        
        changeCaveView.navigationBar.completionButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let caveId = self?.caveId else { return }
                self?.viewModel.inputs.completionButtonTap(caveId: caveId)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.changeCave
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                guard let caveId = self.caveId else { return }
                self.homeViewModel.inputs.caveDetail(caveId: caveId)
                self.homeViewModel.inputs.reloadCave()
                self.popToCaveDetailVC()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - UI Components Property
    
    override func setStyles() {
        
        self.view.backgroundColor = .clear
    }
    
    // MARK: - Layout Helper
    
    override func setLayout() {
        
        self.view.addSubviews(changeCaveView)
        
        changeCaveView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ChangeCaveViewController {
    
    private func setNextTextView() {
        changeCaveView.introduceTextView.becomeFirstResponder()
    }

    private func popToCaveDetailVC() {
        self.navigationController?.popViewController(animated: true)
    }
}
