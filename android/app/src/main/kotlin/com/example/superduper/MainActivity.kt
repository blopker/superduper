package io.kbl.superduper

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.companion.*
import android.content.*
import android.net.MacAddress
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.ParcelUuid
import androidx.annotation.NonNull
import androidx.annotation.UiThread
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*
import java.util.concurrent.Executor
import java.util.regex.Pattern

private const val SELECT_DEVICE_REQUEST_CODE = 0
private var MC: MethodChannel? = null;
fun fprint(log: String) {
    MC!!.invokeMethod("print", log)
}

class MainActivity : FlutterActivity() {
    private val CHANNEL = "io.kbl.superduper/native"
    private val deviceManager: CompanionDeviceManager by lazy {
        getSystemService(Context.COMPANION_DEVICE_SERVICE) as CompanionDeviceManager
    }

    val mBluetoothAdapter: BluetoothAdapter by lazy {
        val java = BluetoothManager::class.java
        getSystemService(java)!!.adapter
    }
    val executor: Executor = Executor { it.run() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//    setContentView(R.layout.activity_main)
        return
        // To skip filters based on names and supported feature flags (UUIDs),
        // omit calls to setNamePattern() and addServiceUuid()
        // respectively, as shown in the following  Bluetooth example.
        val deviceFilter: BluetoothDeviceFilter = BluetoothDeviceFilter.Builder()
            .setNamePattern(Pattern.compile("SUPER73")).build()

        // The argument provided in setSingleDevice() determines whether a single
        // device name or a list of them appears.
        val pairingRequest: AssociationRequest = AssociationRequest.Builder()
            .addDeviceFilter(deviceFilter)
            .setSingleDevice(true)
            .build()

        // When the app tries to pair with a Bluetooth device, show the
        // corresponding dialog box to the user.
        deviceManager.associate(
            pairingRequest,
            executor,
            object : CompanionDeviceManager.Callback() {
                // Called when a device is found. Launch the IntentSender so the user
                // can select the device they want to pair with.
                override fun onAssociationPending(intentSender: IntentSender) {
                    startIntentSenderForResult(
                        intentSender,
                        SELECT_DEVICE_REQUEST_CODE,
                        null,
                        0,
                        0,
                        0
                    )
                }

                override fun onDeviceFound(intentSender: IntentSender) {
                    fprint("on device found")
                    fprint(intentSender.toString())
                    super.onDeviceFound(intentSender)
                }

                override fun onAssociationCreated(associationInfo: AssociationInfo) {
                    // AssociationInfo object is created and get association id and the
                    // macAddress.
                    var associationId: Int = associationInfo.id
                    var macAddress: MacAddress? = associationInfo.deviceMacAddress
                    // fprint("onAssociationCreated")
                    // fprint(associationId.toString())
                    // fprint(macAddress.toString())
                }

                override fun onFailure(errorMessage: CharSequence?) {
                    // Handle the failure.
                }
            }
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            SELECT_DEVICE_REQUEST_CODE -> when (resultCode) {
                Activity.RESULT_OK -> {
                    fprint("Device paired!")
                    // The user chose to pair the app with a Bluetooth device.
                    val deviceToPair: BluetoothDevice? =
                        data?.getParcelableExtra(CompanionDeviceManager.EXTRA_DEVICE)
                    deviceToPair!!.createBond()
                    deviceManager.startObservingDevicePresence(deviceToPair!!.address)
                }
            }
            else -> super.onActivityResult(requestCode, resultCode, data)
        }
    }


    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MC = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        MC!!.setMethodCallHandler { call, result ->
            if (call.method == "getBatteryLevel") {
                val batteryLevel = getBatteryLevel()

                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getBatteryLevel(): Int {
        fprint(deviceManager.myAssociations.toString())
        if (deviceManager.myAssociations.isNotEmpty()) {
            deviceManager.myAssociations.forEach {
                fprint(it.toString())
                deviceManager.startObservingDevicePresence(it.deviceMacAddress.toString())
            }
        }
        val batteryLevel: Int =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val batteryManager =
                    getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            } else {
                val intent = ContextWrapper(applicationContext).registerReceiver(
                    null,
                    IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                )
                intent!!.getIntExtra(
                    BatteryManager.EXTRA_LEVEL,
                    -1
                ) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            }
        fprint(batteryLevel.toString())
        return batteryLevel
    }
}

class CompanionService : CompanionDeviceService() {
    override fun onDeviceAppeared(associationInfo: AssociationInfo) {
        fprint("device found")
        fprint(associationInfo.toString())
        super.onDeviceAppeared(associationInfo)

    }

    override fun onDeviceDisappeared(associationInfo: AssociationInfo) {
        fprint("device left")
        fprint(associationInfo.toString())
        super.onDeviceDisappeared(associationInfo)

    }
}

//class MainActivity : AppCompatActivity() {
//
//  private val deviceManager: CompanionDeviceManager by lazy {
//    getSystemService(Context.COMPANION_DEVICE_SERVICE) as CompanionDeviceManager
//  }
//  val mBluetoothAdapter: BluetoothAdapter by lazy {
//    val java = BluetoothManager::class.java
//    getSystemService(java)!!.adapter }
//  val executor: Executor =  Executor { it.run() }
//
//  override fun onCreate(savedInstanceState: Bundle?) {
//    super.onCreate(savedInstanceState)
//    setContentView(R.layout.activity_main)
//
//    // To skip filters based on names and supported feature flags (UUIDs),
//    // omit calls to setNamePattern() and addServiceUuid()
//    // respectively, as shown in the following  Bluetooth example.
//    val deviceFilter: BluetoothDeviceFilter = BluetoothDeviceFilter.Builder()
//      .setNamePattern(Pattern.compile("My device"))
//      .addServiceUuid(ParcelUuid(UUID(0x123abcL, -1L)), null)
//      .build()
//
//    // The argument provided in setSingleDevice() determines whether a single
//    // device name or a list of them appears.
//    val pairingRequest: AssociationRequest = AssociationRequest.Builder()
//      .addDeviceFilter(deviceFilter)
//      .setSingleDevice(true)
//      .build()
//
//    // When the app tries to pair with a Bluetooth device, show the
//    // corresponding dialog box to the user.
//    deviceManager.associate(pairingRequest,
//      executor,
//      object : CompanionDeviceManager.Callback() {
//        // Called when a device is found. Launch the IntentSender so the user
//        // can select the device they want to pair with.
//        override fun onAssociationPending(intentSender: IntentSender) {
//          intentSender?.let {
//            startIntentSenderForResult(it, SELECT_DEVICE_REQUEST_CODE, null, 0, 0, 0)
//          }
//        }
//
//        override fun onAssociationCreated(associationInfo: AssociationInfo) {
//          // AssociationInfo object is created and get association id and the
//          // macAddress.
//          var associationId: int = associationInfo.id
//          var macAddress: MacAddress = associationInfo.deviceMacAddress
//        }
//        override fun onFailure(errorMessage: CharSequence?) {
//          // Handle the failure.
//        }
//        )
//
//        override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
//          when (requestCode) {
//            SELECT_DEVICE_REQUEST_CODE -> when(resultCode) {
//              Activity.RESULT_OK -> {
//                // The user chose to pair the app with a Bluetooth device.
//                val deviceToPair: BluetoothDevice? =
//                  data?.getParcelableExtra(CompanionDeviceManager.EXTRA_DEVICE)
//                deviceToPair?.let { device ->
//                  device.createBond()
//                  // Maintain continuous interaction with a paired device.
//                }
//              }
//            }
//            else -> super.onActivityResult(requestCode, resultCode, data)
//          }
//        }
//      }
