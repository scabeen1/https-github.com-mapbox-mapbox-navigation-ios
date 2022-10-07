import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import MapboxGeocoder

extension SceneDelegate: PreviewViewControllerDelegate {
    
    func requestRoutes(_ completion: @escaping (_ routeResponse: RouteResponse) -> Void) {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        Directions.shared.calculate(navigationRouteOptions) { (_, result) in
            switch result {
            case .failure(let error):
                print("Error occured while requesting routes: \(error.localizedDescription)")
            case .success(let routeResponse):
                completion(routeResponse)
            }
        }
    }
    
    func willPreviewRoutes(_ previewViewController: PreviewViewController) {
        requestRoutes { routeResponse in
            previewViewController.preview(routeResponse)
        }
    }
    
    func willBeginActiveNavigation(_ previewViewController: PreviewViewController) {
        if let previewViewController = previewViewController.topBanner(.bottomLeading) as? RoutesPreviewViewController {
            let routeResponse = previewViewController.routesPreviewOptions.routeResponse
            startActiveNavigation(for: routeResponse)
        } else {
            requestRoutes { [weak self] routeResponse in
                guard let self = self else { return }
                self.startActiveNavigation(for: routeResponse)
            }
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didAddDestinationBetween coordinates: [CLLocationCoordinate2D]) {
        // In case if `RoutesPreviewViewController` don't do anything.
        if previewViewController.topBanner(.bottomLeading) is RoutesPreviewViewController {
            return
        } else {
            self.coordinates = coordinates
            
            guard let destinationCoordinate = coordinates.last else {
                return
            }
            
            let finalWaypoint = Waypoint(coordinate: destinationCoordinate,
                                         coordinateAccuracy: nil,
                                         name: "Dropped pin")
            
            previewViewController.preview(finalWaypoint)
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelect route: Route) {
        guard let routesPreviewViewController = previewViewController.topBanner(.bottomLeading) as? RoutesPreviewViewController,
              let routes = routesPreviewViewController.routesPreviewOptions.routeResponse.routes,
              let routeIndex = routes.firstIndex(where: { $0 === route }) else {
            return
        }
        
        self.routeIndex = routeIndex
        
        previewViewController.preview(routesPreviewViewController.routesPreviewOptions.routeResponse, routeIndex: routeIndex)
    }
    
    func startActiveNavigation(for routeResponse: RouteResponse) {
        self.previewViewController.navigationView.topBannerContainerView.hide(duration: animationDuration)
        self.previewViewController.navigationView.bottomBannerContainerView.hide(duration: animationDuration,
                                                                                 animations: { [weak self] in
            guard let self = self else { return }
            self.previewViewController.navigationView.floatingStackView.alpha = 0.0
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse,
                                                            routeIndex: self.routeIndex)
            
            let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                            credentials: NavigationSettings.shared.directions.credentials,
                                                            simulating: .always)
            
            let navigationOptions = NavigationOptions(navigationService: navigationService)
            
            let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                    navigationOptions: navigationOptions)
            
            navigationViewController.modalPresentationStyle = .fullScreen
            navigationViewController.transitioningDelegate = self
            
            self.previewViewController.present(navigationViewController,
                                               animated: true,
                                               completion: { [weak self] in
                guard let self = self else { return }
                // Make `SceneDelegate` delegate of `NavigationViewController` to be notified about
                // its dismissal.
                navigationViewController.delegate = self
                
                // Switch navigation camera to active navigation mode.
                navigationViewController.navigationMapView?.navigationCamera.viewportDataSource = NavigationViewportDataSource(navigationViewController.navigationView.navigationMapView.mapView,
                                                                                                                               viewportDataSourceType: .active)
                navigationViewController.navigationMapView?.navigationCamera.follow()
                
                navigationViewController.navigationMapView?.userLocationStyle = .courseView()
                
                // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
                navigationViewController.routeLineTracksTraversal = false
                
                // Hide top and bottom container views before animating their presentation.
                navigationViewController.navigationView.topBannerContainerView.isHidden = true
                navigationViewController.navigationView.bottomBannerContainerView.isHidden = true
                
                navigationViewController.navigationView.speedLimitView.alpha = 0.0
                navigationViewController.navigationView.wayNameView.alpha = 0.0
                navigationViewController.navigationView.floatingStackView.alpha = 0.0
                
                navigationViewController.navigationView.topBannerContainerView.show(duration: self.animationDuration,
                                                                                    animations: {
                    navigationViewController.navigationView.speedLimitView.alpha = 1.0
                    navigationViewController.navigationView.wayNameView.alpha = 1.0
                    navigationViewController.navigationView.floatingStackView.alpha = 1.0
                })
                navigationViewController.navigationView.bottomBannerContainerView.show(duration: self.animationDuration)
            })
        })
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent destinationText: NSAttributedString,
                               in destinationPreviewViewController: DestinationPreviewViewController) -> NSAttributedString? {
        let destinationCoordinate = destinationPreviewViewController.destinationOptions.waypoint.coordinate
        let reverseGeocodeOptions = ReverseGeocodeOptions(coordinate: destinationCoordinate)
        reverseGeocodeOptions.focalLocation = CLLocationManager().location
        reverseGeocodeOptions.locale = Locale.autoupdatingCurrent.languageCode == "en" ? nil : .autoupdatingCurrent
        let allowedScopes: PlacemarkScope = .all
        reverseGeocodeOptions.allowedScopes = allowedScopes
        reverseGeocodeOptions.maximumResultCount = 1
        reverseGeocodeOptions.includesRoutableLocations = true
        
        Geocoder.shared.geocode(reverseGeocodeOptions, completionHandler: { (placemarks, _, error) in
            if let error = error {
                print("Reverse geocoding failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                return
            }
            
            destinationPreviewViewController.destinationOptions.primaryText = placemark.formattedName
        })
        
        return NSAttributedString(string: "")
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent banner: Banner) {
        // No-op
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didPresent banner: Banner) {
        // No-op
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willDismiss banner: Banner) {
        // No-op
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didDismiss banner: Banner) {
        // No-op
    }
}
