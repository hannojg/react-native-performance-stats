import React, { useRef, useState } from 'react';
import {
  View,
  Button,
  Text,
  SafeAreaView,
  StatusBar,
  useColorScheme,
  FlatList,
} from 'react-native';

import {
  Colors,
} from 'react-native/Libraries/NewAppScreen';

import PerformanceStats from "react-native-performance-stats";

const DEV_WITH_UI_UPDATES = false;

const App = () => {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  const [stats, setStats] = useState("");
  const statsUpdatedCallback = (stats) => {
    const statsStr = `UI: ${stats.uiFps.toFixed(2)}fps, JS: ${stats.jsFps.toFixed(2)}fps, Shutters: ${stats.shutters}, RAM: ${stats.usedRam}MB, CPU: ${stats.usedCpu}%\n`;
    if (DEV_WITH_UI_UPDATES){
      setStats((prev) => {
        return prev + statsStr;
      });
    } else {
      console.log(statsStr);
    }
  }

  let prevListenerRef = useRef();
  const onPressStopListener = () => {
    prevListenerRef.current?.remove();
    PerformanceStats.stop();
    prevListenerRef.current = null;
    setStats("");
  }

  const onPressStartListener = () => {
    onPressStopListener();

    prevListenerRef.current = PerformanceStats.addListener(statsUpdatedCallback);
    PerformanceStats.start(true);
  }

  const [isWithList, setIsWithList] = useState(false);
  const onPressCalc = () => {
    setIsWithList(!isWithList);
  }

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <Button title="Start listener" onPress={onPressStartListener} />
      <Button title="Stop listener" onPress={onPressStopListener} />
      <Button title="Press me for degregated performance" onPress={onPressCalc} />

      {DEV_WITH_UI_UPDATES && (
        <Text style={{ marginTop: 100, }}>
          {stats || "Start performance tracking"}
        </Text>
      )}

      {isWithList && (
        <FlatList
          initialNumToRender={100}
          data={Array.from(Array(500).keys())}
          renderItem={({ item }) => (
            <View style={{
              backgroundColor: "#" + Math.floor(Math.random()*16777215).toString(16),
              height: 30,
              width: "100%",
            }}>
              <Text>{item}</Text>
            </View>
          )}
        />
      )}
    </SafeAreaView>
  );
};

export default App;
