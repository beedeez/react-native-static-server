package com.staticserver

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.LifecycleEventListener

import java.io.File
import java.io.IOException
import java.net.InetAddress
import java.net.NetworkInterface
import java.net.SocketException
import java.net.ServerSocket

import android.util.Log

import fi.iki.elonen.SimpleWebServer

class StaticServerModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext), LifecycleEventListener {

  private var wwwRoot: File? = null
  private var port: Int = 9999
  private var localhostOnly: Boolean = false
  private var keepAlive: Boolean = false
  private var localPath: String = ""
  private var server: SimpleWebServer? = null
  private var url: String = ""

  init {
    reactContext.addLifecycleEventListener(this)
  }

  override fun getName(): String {
    return NAME
  }

  private fun getLocalIpAddress(): String {
    try {
      val networkInterfaces = NetworkInterface.getNetworkInterfaces()
      for (intf in networkInterfaces) {
        val addresses = intf.inetAddresses
        for (inetAddress in addresses) {
          if (!inetAddress.isLoopbackAddress) {
            val ip = inetAddress.hostAddress ?: continue
            if (ip.contains(".")) { // Ensuring IPv4
              Log.w(LOG_TAG, "Local IP: $ip")
              return ip
            }
          }
        }
      }
    } catch (ex: SocketException) {
      Log.e(LOG_TAG, ex.toString())
    }
    return "127.0.0.1"
  }

  private fun findRandomOpenPort(): Int {
    val serverSocket = ServerSocket(0)
    val port = serverSocket.localPort
    serverSocket.close()
    return port
  }

  @ReactMethod
  fun start(portInput: String?, root: String?, localhost: Boolean?, keepAliveFlag: Boolean?, promise: Promise) {
    if (server != null) {
      promise.resolve(url)
      return
    }

    port = try {
      portInput?.toInt()?.takeIf { it > 0 } ?: findRandomOpenPort()
    } catch (e: NumberFormatException) {
      findRandomOpenPort()
    }

    wwwRoot = if (root != null && (root.startsWith("/") || root.startsWith("file:///"))) {
      File(root)
    } else {
      File(reactApplicationContext.filesDir, root ?: "")
    }
    localPath = wwwRoot?.absolutePath ?: ""

    localhostOnly = localhost ?: false
    keepAlive = keepAliveFlag ?: false

    try {
      val host = if (localhostOnly) "localhost" else getLocalIpAddress()

      server = SimpleWebServer(host, port, wwwRoot, true /* allowDirectoryListing */)

      url = "http://$host:$port"
      server?.start()

      promise.resolve(url)
    } catch (e: IOException) {
      if (server != null && e.message == "bind failed: EADDRINUSE (Address already in use)") {
        promise.resolve(url)
      } else {
        promise.reject(null, e.message)
      }
    }
  }

  @ReactMethod
  fun stop() {
    server?.let {
      Log.w(LOG_TAG, "Stopped Server")
      it.stop()
      server = null
    }
  }

  @ReactMethod
  fun origin(promise: Promise) {
    promise.resolve(server?.let { url } ?: "")
  }

  @ReactMethod
  fun isRunning(promise: Promise) {
    promise.resolve(server?.isAlive ?: false)
  }

  override fun onHostResume() {
    Log.d(LOG_TAG, "onHostResume called")
  }

  override fun onHostPause() {
    Log.d(LOG_TAG, "onHostPause called")
  }

  override fun onHostDestroy() {
    stop()
  }

  companion object {
    const val NAME = "StaticServer"
    private const val LOG_TAG = "StaticServerModule"
  }
}