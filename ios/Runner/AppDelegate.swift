import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let galleryChannel = "com.mnivesh.central.mnivesh_central/gallery"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: galleryChannel,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "saveImage" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let args = call.arguments as? [String: Any],
          let imageBytes = (args["bytes"] as? FlutterStandardTypedData)?.data,
          let title = args["title"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "Image bytes and title are required.",
              details: nil
            )
          )
          return
        }

        self?.saveImageToPhotos(data: imageBytes, title: title, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle custom URL schemes
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  private func saveImageToPhotos(
    data: Data,
    title: String,
    result: @escaping FlutterResult
  ) {
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        result(
          FlutterError(
            code: "permission_denied",
            message: "Photos permission not granted.",
            details: nil
          )
        )
        return
      }

      PHPhotoLibrary.shared().performChanges({
        let creationRequest = PHAssetCreationRequest.forAsset()
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = "\(title)_\(Int(Date().timeIntervalSince1970)).png"
        creationRequest.addResource(with: .photo, data: data, options: options)
      }) { success, error in
        if let error {
          result(
            FlutterError(
              code: "save_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }

        if success {
          result("photos://saved")
        } else {
          result(
            FlutterError(
              code: "save_failed",
              message: "Failed to save image to Photos.",
              details: nil
            )
          )
        }
      }
    }
  }
}
