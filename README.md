# react-native-static-server

RN Static Server

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
