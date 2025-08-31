import { useState } from "react";
import ExpoMlkitCustomObjectDetection, {
  DetectedObject,
} from "expo-mlkit-custom-object-detection";
import {
  Button,
  SafeAreaView,
  ScrollView,
  Text,
  View,
  Image,
  Alert,
} from "react-native";
import { Image as RNImage } from "react-native";

export default function App() {
  const [detectionResults, setDetectionResults] = useState<DetectedObject[]>(
    []
  );
  const [isDetecting, setIsDetecting] = useState(false);

  const detectObjectsInImage = async () => {
    try {
      console.log(111);
      setIsDetecting(true);
      const ballImage = require("./assets/ball_2.png");
      const source = RNImage.resolveAssetSource(ballImage);
      const ballImagePath = source.uri;
      console.log("Image path:", ballImagePath);

      const results =
        await ExpoMlkitCustomObjectDetection.detectObjects(ballImagePath);
      setDetectionResults(results);
      console.log("Detection results:", results);

      Alert.alert("Detection Complete", `Found ${results.length} object(s)`);
    } catch (error) {
      console.error("Detection error:", error);
      Alert.alert("Error", "Failed to detect objects in image");
    } finally {
      setIsDetecting(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>MLKit Object Detection</Text>

        <Group name="Test Image">
          <Image
            source={require("./assets/ball_2.png")}
            style={styles.image}
            resizeMode="contain"
          />
        </Group>

        <Group name="Object Detection">
          <Button
            title={isDetecting ? "Detecting..." : "Detect Objects"}
            onPress={detectObjectsInImage}
            disabled={isDetecting}
          />
        </Group>

        <Group name="Results">
          {detectionResults.length > 0 ? (
            detectionResults.map((object, index) => (
              <View key={index} style={styles.resultItem}>
                <Text style={styles.resultText}>Object {index + 1}:</Text>
                <Text>
                  Bounding Box: {JSON.stringify(object.boundingBox, null, 2)}
                </Text>
                {object.trackingId && (
                  <Text>Tracking ID: {object.trackingId}</Text>
                )}
                {object.labels && object.labels.length > 0 && (
                  <View>
                    <Text>Labels:</Text>
                    {object.labels.map((label, labelIndex) => (
                      <Text key={labelIndex} style={styles.labelText}>
                        - {label.text} (confidence:{" "}
                        {(label.confidence * 100).toFixed(1)}%)
                      </Text>
                    ))}
                  </View>
                )}
              </View>
            ))
          ) : (
            <Text>No objects detected yet</Text>
          )}
        </Group>
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20,
    textAlign: "center" as const,
    fontWeight: "bold" as const,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
    fontWeight: "bold" as const,
  },
  group: {
    margin: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: "#eee",
  },
  image: {
    width: 200,
    height: 200,
    alignSelf: "center" as const,
    marginBottom: 10,
  },
  resultItem: {
    marginBottom: 15,
    padding: 10,
    backgroundColor: "#f9f9f9",
    borderRadius: 5,
  },
  resultText: {
    fontWeight: "bold" as const,
    marginBottom: 5,
  },
  labelText: {
    marginLeft: 10,
    color: "#666",
  },
};
