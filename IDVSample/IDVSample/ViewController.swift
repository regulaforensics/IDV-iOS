//
//  ViewController.swift
//  IDVSample
//
//  Created by Serge Rylko on 19.03.25.
//

import UIKit
import IDVSDK

class ViewController: UIViewController {

  @IBOutlet private weak var loadingActivity: UIActivityIndicatorView!
  @IBOutlet private weak var startWorkflowButton: UIButton!

  private lazy var credentials: Credentials = {
    .init(userName: "regula-idv" , //INSERT
          password: "", //INSERT
          host: "https://idv.regula.app",
          workflowId: "") //INSERT
  }()

  private var latestPreparedWorkflowId: String? {
    didSet { updateStartButtonAppearance() }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    initializeIDV()
  }

  // MARK: - IDV Calls
  private func initializeIDV() {
    showLoading()

    IDV.shared.initialize(config: .init()) { result in
      self.hideLoading()

      switch result {
      case .success:
        print("Init completed")
      case .failure(let error):
        print("Init failed", error.fullChain)
      }
    }
  }

  private func configure(with url: String) {
    showLoading()

    IDV.shared.configure(with: .init(url: url)) { configureResults in
      self.hideLoading()

      switch configureResults {
      case .success(let workflowIds):
        if let workflowId = workflowIds.first {
          self.prepareWorkflow(workflowId: workflowId)
        } else {
          print("Workflow configuration failed")
        }
      case .failure(let error):
        print("Configure failed", error.fullChain)
      }
    }
  }

  private func configureByCredentials() {
    guard credentials.isValid() else {
      print("Invalid credentials")
      return
    }
    let config = IDVConnectionConfig(userName: credentials.userName,
                                     password: credentials.password,
                                     url: credentials.host)
    showLoading()

    IDV.shared.configure(with: config) { result in
      self.hideLoading()

      switch result {
      case .success:
        self.prepareWorkflow(workflowId: self.credentials.workflowId)
      case .failure(let error):
        print(error.fullChain)
      }
    }
  }

  private func prepareWorkflow(workflowId: String) {
    let workflowConfig = WorkflowConfig(workflowId: workflowId)
    self.showLoading()
    IDV.shared.prepareWorkflow(by: workflowConfig) { prepareResults in
      self.hideLoading()

      switch prepareResults {
      case .success:
        self.latestPreparedWorkflowId = workflowId
        self.startWorkflow(workflowId: workflowId)
      case .failure(let error):
        print(error.fullChain)
      }
    }
  }

  private func startWorkflow(workflowId: String) {
    var config = StartWorkflowConfig.default()
    config.metadata = ["test": true]
    config.locale = "en"

    IDV.shared.startWorkflow(presenter: self) { result in
      switch result {
      case .success(let results):
        print("Completed", results.sessionId)
      case .failure(let error):
        print(error.fullChain)
      }
    }
  }

  //MARK: - Actions
  @IBAction private func didPressConfigureByURL(_ sender: Any) {
    let scanController = ScanViewController()
    scanController.delegate = self
    navigationController?.pushViewController(scanController, animated: true)
  }

  @IBAction private func didPressConfigureByCredentials(_ sender: Any) {
    configureByCredentials()
  }

  @IBAction private func didPressStartWorkflow(_ sender: Any) {
    guard let latestPreparedWorkflowId else { return }
    startWorkflow(workflowId: latestPreparedWorkflowId)
  }

  //MARK: Supplementary
  private func showLoading() {
    view.isUserInteractionEnabled = false
    loadingActivity.startAnimating()
  }
  
  private func hideLoading() {
    view.isUserInteractionEnabled = true
    loadingActivity.stopAnimating()
  }

  private func updateStartButtonAppearance() {
    startWorkflowButton.isEnabled = latestPreparedWorkflowId != nil
  }
}

extension ViewController: ScanViewControllerDelegate {

  func didDetectQRCode(controller: ScanViewController, code: String) {
    configure(with: code)
  }

  func didReceiveScanError(controller: ScanViewController, error: ScanError) {
    print(error)
  }
}

