//
// Copyright 2025 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//


import SignalServiceKit
import SignalUI

public struct RegistrationSpeechToTextState: Equatable {
    public init() {}
}

protocol RegistrationSpeechToTextPresenter: AnyObject {
    func continueToNextStep()
    func skipStep()
}

class RegistrationSpeechToTextViewController: OWSViewController {
    private let state: RegistrationSpeechToTextState
    private weak var presenter: RegistrationSpeechToTextPresenter?
    
    init(state: RegistrationSpeechToTextState, presenter: RegistrationSpeechToTextPresenter) {
        self.state = state
        self.presenter = presenter
        super.init()
    }
    
    public func updateState(_ state: RegistrationSpeechToTextState) {
        // Aggiorna lo stato se necessario
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.setHidesBackButton(true, animated: false)
        
        let registrationSpeechToTextView = RegistrationSpeechToTextView()
        registrationSpeechToTextView.delegate = self
        view.addSubview(registrationSpeechToTextView)
        registrationSpeechToTextView.autoPinEdgesToSuperviewEdges()
    }
}

extension RegistrationSpeechToTextViewController: RegistrationSpeechToTextViewDelegate {
    func registrationSpeechToTextViewDidTapContinue(withOption option: RegistrationSpeechToTextView.SpeechToTextOption) {
        presenter?.continueToNextStep()
    }
    
    func registrationSpeechToTextViewDidSelect(option: RegistrationSpeechToTextView.SpeechToTextOption) {
        print("ciao")
    }
    
    func registrationSpeechToTextViewDidTapSkip() {
        presenter?.skipStep()
    }
}
