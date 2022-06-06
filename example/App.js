import React, { useRef } from 'react';
import {
  Button,
  SafeAreaView,
  StatusBar,
  useColorScheme,
} from 'react-native';

import {
  Colors,
} from 'react-native/Libraries/NewAppScreen';

import PerformanceStats from "react-native-performance-stats";

function fibonacci(n) {
  return n < 1 ? 0
       : n <= 2 ? 1
       : fibonacci(n - 1) + fibonacci(n - 2)
}

const App = () => {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  const statUpdateCallback = (stats) => {
    console.log({stats});
  }

  let prevListenerRef = useRef();
  const onPressStopListener = () => {
    prevListenerRef.current?.remove();
    PerformanceStats.stop();
    prevListenerRef.current = null;
  }

  const onPressStartListener = () => {
    onPressStopListener();

    prevListenerRef.current = PerformanceStats.addListener(statUpdateCallback);
    PerformanceStats.start();
  }

  const onPressCalc = () => {
    console.log(fibonacci(32));
  }

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <Button title="Start listener" onPress={onPressStartListener} />
      <Button title="Stop listener" onPress={onPressStopListener} />
      <Button title="Press me for degregated performance" onPress={onPressCalc} />
    </SafeAreaView>
  );
};

export default App;
