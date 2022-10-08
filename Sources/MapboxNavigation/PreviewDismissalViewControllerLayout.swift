import UIKit

extension PreviewDismissalViewController {
    
    func setupConstraints() {
        let parentViewsLayoutConstraints = [
            topPaddingView.topAnchor.constraint(equalTo: view.topAnchor),
            topPaddingView.bottomAnchor.constraint(equalTo: topBannerView.topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            topBannerView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            topBannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            topBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]
        
        NSLayoutConstraint.activate(parentViewsLayoutConstraints)
        
        // TODO: Verify that back button is shown correctly for right-to-left languages.
        let backButtonLayoutConstraints = [
            backButton.widthAnchor.constraint(equalToConstant: 110.0),
            backButton.heightAnchor.constraint(equalToConstant: 50.0),
            backButton.leadingAnchor.constraint(equalTo: topBannerView.leadingAnchor,
                                                constant: 10.0),
            backButton.topAnchor.constraint(equalTo: topBannerView.topAnchor,
                                               constant: 10.0)
        ]
        
        NSLayoutConstraint.activate(backButtonLayoutConstraints)
    }
}
