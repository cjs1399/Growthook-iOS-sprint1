//
//  MyPageViewModel.swift
//  Growthook
//
//  Created by KYUBO A. SHIM on 12/15/23.
//

import UIKit

import RxCocoa
import RxSwift

protocol MyPageViewModelInputs {
    func checkMyInformationDidTap()
    func growthookManualDidTap()
    func announcementDidTap()
    func frequentQuestionsDidTap()
    func termsAndPoliciesDidTap()
    func logOutDidTap()
    
    func reloadSsuk()
}

protocol MyPageViewModelOutputs {
    var userProfileImageUrl: BehaviorRelay<String> { get }
    var userProfileName: BehaviorRelay<String> { get }
    var userEmail: BehaviorRelay<String> { get }
    var userEarnedThookCount: BehaviorRelay<Int> { get }
    var userSpentThookCount: BehaviorRelay<Int> { get }
    var myPageComponentsList: BehaviorRelay<[String]> { get }
    var versionNumber: BehaviorRelay<String> { get }
    var networkState: BehaviorRelay<SomeNetworkStatus> { get }
}

protocol MyPageViewModelType {
    var inputs: MyPageViewModelInputs { get }
    var outputs: MyPageViewModelOutputs { get }
}

final class MyPageViewModel: MyPageViewModelInputs, MyPageViewModelOutputs, MyPageViewModelType {
    
    var userProfileImageUrl: BehaviorRelay<String> = BehaviorRelay(value: "")
    var userProfileName: BehaviorRelay<String> = BehaviorRelay(value: "")
    var userEmail: BehaviorRelay<String> = BehaviorRelay(value: "")
    var userEarnedThookCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    var userSpentThookCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    var myPageComponentsList: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    var versionNumber = BehaviorRelay(value: "0.0.0")
    var networkState = BehaviorRelay<SomeNetworkStatus>(value: .normal)
    
    private let memberId = UserDefaults.standard.integer(forKey: I18N.Auth.memberId)
    private let myPageList: [String] = [
        "growthook 사용법", "공지사항", "자주 묻는 질문",
        "약관 및 정책", "버전 정보", "로그아웃"
    ]
    private let disposeBag = DisposeBag()
    
    var inputs: MyPageViewModelInputs { return self }
    var outputs: MyPageViewModelOutputs { return self }
    
    // TODO: memberId 를 어디서 어떻게 Get 할까요?
    init() {
        myPageComponentsList.accept(myPageList)
        setVersionOfTheApp()
        getUserInformation()
    }
    
    func checkMyInformationDidTap() {
        print("EditMyInformation Tapped")
    }
    
    func growthookManualDidTap() {
        if let url = URL(string: "https://www.notion.so/a6ac706599224bbbb9f7a6b449c1a02f") {
            UIApplication.shared.open(url)
        }
    }
    
    func announcementDidTap() {
        if let url = URL(string: "https://www.notion.so/9bba9068c49e42d98e0d9b5bd59674c9") {
            UIApplication.shared.open(url)
        }
    }
    
    func frequentQuestionsDidTap() {
        if let url = URL(string: "https://groovy-need-069.notion.site/6cdc4f9f7f38490084a89da1bfa083ab?pvs=4") {
            UIApplication.shared.open(url)
        }
    }
    
    func termsAndPoliciesDidTap() {
        if let url = URL(string: "https://www.notion.so/9edc8ab432d34da682b9320f9bc6fd31") {
            UIApplication.shared.open(url)
        }
    }
    
    func logOutDidTap() {
        print("LogOut Tapped")
        UserDefaults.standard.removeObject(forKey: I18N.Auth.nickname)
        UserDefaults.standard.removeObject(forKey: I18N.Auth.memberId)
//        UserDefaults.standard.removeObject(forKey: I18N.Auth.jwtToken)
//        UserDefaults.standard.removeObject(forKey: I18N.Auth.refreshToken)
        KeychainHelper.delete(key: I18N.Auth.jwtToken)
        KeychainHelper.delete(key: I18N.Auth.refreshToken)
        UserDefaults.standard.set(false ,forKey: "isLoggedIn")
    }
    
    func reloadSsuk() {
        getUserInformation()
    }
}

extension MyPageViewModel {
    
    private func setDummyData() {
        userProfileImageUrl.accept("https://i.pravatar.cc/300")
    }
    
    private func setVersionOfTheApp() {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return
        }
        versionNumber.accept(version)
    }
}

extension MyPageViewModel {
    
    private func getUserInformation() {
        MyPageService.getUserInfo(with: memberId)
            .subscribe(onNext: { [weak self] profile in
                guard let self else { return }
                self.userProfileName.accept(profile.nickname)
                self.userEmail.accept(profile.email)
                self.userProfileImageUrl.accept(profile.profileImage ?? "")
            }, onError: { [weak self] error in
                guard let self else { return }
                self.networkState.accept(.error(error))
            })
            .disposed(by: disposeBag)
        
        MyPageService.getEarnedSsuck(with: memberId)
            .subscribe(onNext: { [weak self] ssuk in
                guard let self else { return }
                self.userEarnedThookCount.accept(ssuk.gatheredSsuk)
            }, onError: { [weak self] error in
                guard let self else { return }
                self.networkState.accept(.error(error))
            })
            .disposed(by: disposeBag)
        
        MyPageService.getSpentSsuk(with: memberId)
            .subscribe(onNext: { [weak self] ssuk in
                guard let self else { return }
                self.userSpentThookCount.accept(ssuk.usedSsuk)
            }, onError: { [weak self] error in
                guard let self else { return }
                self.networkState.accept(.error(error))
            })
            .disposed(by: disposeBag)
    }
}
