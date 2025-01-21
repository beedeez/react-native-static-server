import {
  AppState,
  type AppStateStatus,
  Platform,
  NativeModules,
} from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-static-server' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const NativeStaticServer = NativeModules.StaticServer
  ? NativeModules.StaticServer
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

interface StaticServerOptions {
  localOnly?: boolean;
  keepAlive?: boolean;
}

class StaticServer {
  #port: string;
  #root: string | null;
  #localOnly: boolean;
  #keepAlive: boolean;
  #origin?: string;
  #running: boolean = false;
  #started: boolean = false;
  #appStateSub?: { remove: () => void };

  constructor(
    port: number,
    root: string | null = null,
    opts: StaticServerOptions = {}
  ) {
    if (typeof port === 'object') {
      opts = port;
      this.#port = '';
      this.#root = null;
    } else {
      this.#port = String(port) || '';
      this.#root = typeof root === 'string' ? root : null;
    }

    this.#localOnly = opts.localOnly ?? false;
    this.#keepAlive = opts.keepAlive ?? false;
  }

  async start(): Promise<string | undefined> {
    if (this.#running) return this.#origin;

    this.#started = true;
    this.#running = true;

    if (!this.#keepAlive && Platform.OS === 'android') {
      this.#appStateSub = AppState.addEventListener(
        'change',
        this.#handleAppStateChange
      );
    }

    try {
      this.#origin = await NativeStaticServer.start(
        this.#port,
        this.#root ?? '',
        this.#localOnly,
        this.#keepAlive
      );
      return this.#origin;
    } catch (error) {
      this.#running = false;
      throw error;
    }
  }

  async stop(): Promise<void> {
    if (!this.#running) return;

    this.#running = false;
    await NativeStaticServer.stop();
  }

  async kill(): Promise<void> {
    await this.stop();
    this.#started = false;
    this.#origin = undefined;

    if (this.#appStateSub) {
      this.#appStateSub.remove();
      this.#appStateSub = undefined;
    }
  }

  #handleAppStateChange = (appState: AppStateStatus): void => {
    if (!this.#started) return;

    if (appState === 'active' && !this.#running) {
      this.start();
    } else if (appState === 'background' || appState === 'inactive') {
      this.stop();
    }
  };

  get origin(): string | undefined {
    return this.#origin;
  }

  async isRunning(): Promise<boolean> {
    this.#running = await NativeStaticServer.isRunning();
    return this.#running;
  }
}

export default StaticServer;
