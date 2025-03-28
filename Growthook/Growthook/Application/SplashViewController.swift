//
//  SplashViewController.swift
//  Growthook
//
//  Created by KYUBO A. SHIM on 11/12/23.
//

import UIKit

import Lottie

final class SplashViewController: BaseViewController {
    
    private let splashLottieView: LottieAnimationView = LottieAnimationView(name: "grothooksplash", configuration: LottieConfiguration(renderingEngine: .mainThread))
    private let splashLabel = UILabel()
    private let splashImageView = UIImageView()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.isUserLoggedIn() {
                APIConstants.jwtToken = KeychainHelper.loadString(key: I18N.Auth.jwtToken) ?? ""
                APIConstants.refreshToken = KeychainHelper.loadString(key: I18N.Auth.refreshToken) ?? ""
                if let jwtToken = KeychainHelper.loadString(key: I18N.Auth.jwtToken), !jwtToken.isEmpty {
                    AuthAPI.shared.getRefreshToken() { [weak self] response in
                        guard let status = response?.status else { return }
                        if status == 401 {
                            print("아직 토큰이 유효합니다")
                            self?.getNewToken()
                            self?.openTabBar()
                        } else {
                            guard let data = response?.data else { return }
                            APIConstants.jwtToken = data.accessToken
                            APIConstants.refreshToken = data.refreshToken

                            if let accessTokenData = data.accessToken.data(using: .utf8) {
                                KeychainHelper.save(key: I18N.Auth.jwtToken, data: accessTokenData)
                            }

                            if let refreshTokenData = data.refreshToken.data(using: .utf8) {
                                KeychainHelper.save(key: I18N.Auth.refreshToken, data: refreshTokenData)
                            }
                            self?.openTabBar()
                        }
                    }
                }
            } else if self.isFirstLaunch() {
                self.deleteAllRemainingKeyChains()
                self.openOnboarding()
            } else {
                self.openOnboarding()
            }
        }
    }
    
    override func setStyles() {
        view.backgroundColor = .gray700.withAlphaComponent(0.9)
        
        splashLabel.do {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            
            let attributedText = NSAttributedString(
                string: "일상 속 영감이\n성장의 거름으로",
                attributes: [
                    .foregroundColor: UIColor.white000,
                    .font: UIFont.fontGuide(.body1_reg),
                    .paragraphStyle: paragraphStyle
                ]
            )
            
            $0.attributedText = attributedText
            $0.textAlignment = .center
            $0.numberOfLines = 2
        }
        
        splashImageView.do {
            $0.image = ImageLiterals.Onboarding.growthook_Splash
            $0.contentMode = .scaleAspectFit
        }
    }
    
    override func setLayout() {
        view.addSubviews(splashLabel, splashImageView)
        
        splashLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(splashImageView.snp.top).inset(7)
        }
        
        splashImageView.snp.makeConstraints {
            $0.bottom.leading.trailing.equalToSuperview()
            $0.height.equalTo(491)
        }
    }
    
    //MARK: - Methods
    
    /**
     어플리케이션이 최초로 실행되었는지를 확인하는 메소드입니다
     로그인 기능이 아직 최종 구현이 되지 않았기에 아래처럼 구현 하였습니다
     */
    
    private func isFirstLaunch() -> Bool {
        let hasBeenLaunchedBefore = UserDefaults.standard.bool(forKey: I18N.Auth.hasBeenLaunched)
        if !hasBeenLaunchedBefore {
            UserDefaults.standard.set(true, forKey: I18N.Auth.hasBeenLaunched)
        }
        return !hasBeenLaunchedBefore
    }
    
    /**
     사용자가 로그인 되어 있는지 여부를 확인합니다
     예를 들어, 사용자의 토큰이 있는지 확인할 수 있고.,., 네..
     지금은 일단 로그인을 하고 로그아웃을 하지 않고 앱을 종료하면
     아래의 값이 true이기 때문에 Onboarding으로 가지 않고 Tabbar로 갑니다
     */
    
    private func isUserLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: I18N.Auth.isLoggedIn)
    }
    
    
    private func openOnboarding() {
        let mainViewController = OnboardingSelectViewController()
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }
        sceneDelegate.window?.rootViewController = UINavigationController(rootViewController: mainViewController)
        sceneDelegate.window?.makeKeyAndVisible()
    }
    
    private func openTabBar() {
        let mainViewController = TabBarController()
        mainViewController.selectedIndex = 0
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }
        sceneDelegate.window?.rootViewController = UINavigationController(rootViewController: mainViewController)
        sceneDelegate.window?.makeKeyAndVisible()
    }
    
    private func deleteAllRemainingKeyChains() {
        KeychainHelper.delete(key: I18N.Auth.jwtToken)
        KeychainHelper.delete(key: I18N.Auth.refreshToken)
    }
    
    private func getNewToken() {
        AuthAPI.shared.getRefreshToken() { [weak self] response in
            guard self != nil else { return }
            guard let data = response?.data else { return }
            guard let status = response?.status else { return }
            if let accessTokenData = data.accessToken.data(using: .utf8) {
                KeychainHelper.save(key: I18N.Auth.jwtToken, data: accessTokenData)
            }

            if let refreshTokenData = data.refreshToken.data(using: .utf8) {
                KeychainHelper.save(key: I18N.Auth.refreshToken, data: refreshTokenData)
            }
            APIConstants.jwtToken = KeychainHelper.loadString(key: I18N.Auth.jwtToken) ?? ""
            APIConstants.refreshToken = KeychainHelper.loadString(key: I18N.Auth.refreshToken) ?? ""
        }
    }
}
