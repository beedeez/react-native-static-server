# React Native Static Server

This is a fork of https://www.npmjs.com/package/@dr.pogodin/react-native-static-server/v/0.5.5
That's the original package that we were using in Beedeez-Main prior to the migration to React Native 0.74

What I did:

- Modernized the codebase to be compatible with the latest version of React Native
- Migrated from Objective-C to Swift
- Migrated from Java to Kotlin
- Migrated from JS to TS

## Installation

```sh
npm install react-native-static-server
```

## Usage

```js
import StaticServer from 'react-native-static-server';

const server = new StaticServer(8080, '/path/to/your/www', {
  localOnly: true,
  keepAlive: true,
});

server.start();
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
