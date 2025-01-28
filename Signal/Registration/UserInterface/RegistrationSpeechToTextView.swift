//
// Copyright 2025 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import UIKit
import SignalServiceKit
import SignalUI

class RegistrationSpeechToTextView: UIView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel.titleLabelForRegistration(text: OWSLocalizedString(
            "REGISTRATION_SPEECH_TO_TEXT_TITLE",
            comment: "Title for the speech to text registration screen"
        ))
        label.accessibilityIdentifier = "RegistrationSpeechToText.titleLabel"
        return label
    }()
    
    private lazy var explanationLabel: UILabel = {
        let label = UILabel.explanationLabelForRegistration(text: OWSLocalizedString(
            "REGISTRATION_SPEECH_TO_TEXT_DESCRIPTION",
            comment: "Description for the speech to text registration screen"
        ))
        label.accessibilityIdentifier = "RegistrationSpeechToText.explanationLabel"
        return label
    }()
    
    private lazy var continueButton: OWSFlatButton = {
        let button = OWSFlatButton.primaryButtonForRegistration(
            title: OWSLocalizedString(
                "REGISTRATION_SPEECH_TO_TEXT_CONTINUE",
                comment: "Button to continue with speech to text registration"
            ),
            target: self,
            selector: #selector(didTapContinue)
        )
        button.accessibilityIdentifier = "RegistrationSpeechToText.continueButton"
        return button
    }()

    private lazy var skipButton: OWSFlatButton = {
        let button = OWSFlatButton.button(
            title: OWSLocalizedString(
                "REGISTRATION_SPEECH_TO_TEXT_SKIP",
                comment: "Button to skip speech to text registration"
            ),
            font: .dynamicTypeSubheadlineClamped,
            titleColor: Theme.accentBlueColor,
            backgroundColor: .clear,
            target: self,
            selector: #selector(didTapSkip)
        )
        button.accessibilityIdentifier = "RegistrationSpeechToText.skipButton"
        return button
    }()
    
    weak var delegate: RegistrationSpeechToTextViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Theme.backgroundColor
        
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            explanationLabel,
            UIView.vStretchingSpacer(),
            continueButton,
            skipButton
        ])
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        stackView.setCustomSpacing(24, after: explanationLabel)
        stackView.setCustomSpacing(8, after: continueButton)
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewMargins()
    }
    
    @objc
    private func didTapContinue() {
        delegate?.registrationSpeechToTextViewDidTapContinue()
    }

    @objc
    private func didTapSkip() {
        delegate?.registrationSpeechToTextViewDidTapSkip()
    }
}

protocol RegistrationSpeechToTextViewDelegate: AnyObject {
    func registrationSpeechToTextViewDidTapContinue()
    func registrationSpeechToTextViewDidTapSkip()
}
