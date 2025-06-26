# **IDV SDK Integration Guide**

## **Introduction**

This guide provides step-by-step instructions on integrating the **IDV SDK** into an iOS application. 
It covers initialization, API configuration, workflow setup, and starting the ID verification process.


## **1. Prerequisites**

Before integrating the SDK, ensure the following:
- Xcode version is 16.0 and above.
- The application Minimum Deployment Target is **iOS 13.0** and above.
- The `Near Field Communication Tag Reading` capability is enabled the application target.


## **2. IDV dependencies setup** 
1. Add `IDVSDK` dependency to `Podfile`.
2. Add `IDVDocumentReader` dependency. The dependency is optional. 
2.1 Add `IDVDocumentReader` dependency to `Podfile`. 
2.2. Add the DocumentReader Core (e.g: `DocumentReaderFullAuthRFID`) according youre requirements.
2.3. Add **regula.license** file to the application target. Setting is for `IDVDocumentReader` dependency.
2.4. Add **db.dat** file to the application target to use local database.
3. Add `IDVFaceSDK` dependency. The dependency is optional.
3.1. Add `IDVFaceSDK` dependency to `Podfile`.
3.2. Add the FaceSDK Core dependency `FaceCoreBasic`.
4. Run `pod install`.


## **3. Info.plist file setup**
1. Set the description for **NSCameraUsageDescription** setting.
2. Set **NFC** settings:
```xml
<key>com.apple.developer.nfc.readersession.felica.systemcodes</key>
    <array>
        <string>12FC</string>
    </array>
    <key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A0000002471001</string>
        <string>E80704007F00070302</string>
        <string>A000000167455349474E</string>
        <string>A0000002480100</string>
        <string>A0000002480200</string>
        <string>A0000002480300</string>
        <string>A00000045645444C2D3031</string>
    </array>
```


## **4. Initialize Regula IDV SDK**

In your swift code import the framework and initialize the SDK :

```swift
import IDVSDK

IDV.shared.initialize { result in
  // handle initialize results
}
```


## **5. Configure API Settings**

Before using the SDK, configure the API connection:

```swift
let userName = "your_username"
let password = "your_password"
let hostURL = "https://your_host_url.com"
let connectinConfig = IDVConnectionConfig(userName: userName,
                                          password: password,
                                          url: hostURL)
IDV.shared.configure(with: connectinConfig) { result in
  // handle connection results
}
```


## **6. Prepare and Start an ID Verification Workflow**

```swift
let workflowId = "your_workflow_id"
let workflowConfig = WorkflowConfig(workflowId: workflowId)
IDV.shared.prepareWorkflow(by: workflowConfig) { results in
    // handle prepare workflow results
}
```

Start the workflow when ready:

```swift
IDV.shared.startWorkflow(presenter: presenterViewController) { result in
    switch result {
    case .success:
        // handle success
    case .failure(let error):
        //handle error
    }
}
```

To start workflow with metadata dictionary: 

```swift
var config = StartWorkflowConfig.default()
config.metadata = ["key": "value"]
IDV.shared.startWorkflow(presenter: self, config: config) { result in
  switch result {
  case .success:
    // handle success
  case .failure(let error):
    //handle error
  }
}
```

To start workflow with locale language: 

```swift
var config = StartWorkflowConfig.default()
config.locale = "en"
IDV.shared.startWorkflow(presenter: self, config: config) { result in
  switch result {
  case .success:
    // handle success
  case .failure(let error):
    //handle error
  }
}
```

## **7. Best Practices & Troubleshooting**

- **Grant camera permissions** before starting the workflow.
- **Use proper credentials** when configuring `IDVConnectionConfig`.

---

## **Conclusion**

This guide provides all necessary steps to integrate the **Regula IDV SDK** into an iOS application. By following these instructions, developers can build a document verification feature using Regula’s technology.

For further details, refer to the **official Regula IDV SDK documentation** or contact their support team.
