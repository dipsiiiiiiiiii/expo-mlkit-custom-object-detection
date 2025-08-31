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
  const [isModelLoaded, setIsModelLoaded] = useState(false);
  const [modelLoadStatus, setModelLoadStatus] = useState<string>("");

  const loadYoloModel = async () => {
    try {
      setModelLoadStatus("Loading YOLO model...");
      
      // Get the actual file path for the YOLO model
      const modelAsset = require("./assets/models/yolo11n_float32.tflite");
      const modelSource = RNImage.resolveAssetSource(modelAsset);
      const modelPath = modelSource.uri;
      
      console.log("Model path:", modelPath);
      
      const result = await ExpoMlkitCustomObjectDetection.loadCustomModel(modelPath);
      setIsModelLoaded(true);
      setModelLoadStatus("YOLO model loaded successfully!");
      Alert.alert("Success", "YOLO model loaded successfully!");
    } catch (error) {
      console.error("Model load error:", error);
      setModelLoadStatus("Failed to load YOLO model");
      Alert.alert("Error", "Failed to load YOLO model");
    }
  };

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

  const detectObjectsWithYolo = async () => {
    try {
      setIsDetecting(true);
      const ballImage = require("./assets/ball_2.png");
      const source = RNImage.resolveAssetSource(ballImage);
      const ballImagePath = source.uri;
      console.log("Detecting with YOLO model, image path:", ballImagePath);

      const results = await ExpoMlkitCustomObjectDetection.detectObjectsWithCustomModel(ballImagePath);
      setDetectionResults(results);
      console.log("YOLO Detection results:", results);

      Alert.alert("YOLO Detection Complete", `Found ${results.length} object(s)`);
    } catch (error) {
      console.error("YOLO Detection error:", error);
      Alert.alert("Error", "Failed to detect objects with YOLO model");
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

        <Group name="YOLO Model">
          <Text style={styles.statusText}>{modelLoadStatus}</Text>
          <Button
            title="Load YOLO Model"
            onPress={loadYoloModel}
            disabled={isModelLoaded}
          />
        </Group>

        <Group name="Object Detection">
          <Button
            title={isDetecting ? "Detecting..." : "Detect Objects (MLKit)"}
            onPress={detectObjectsInImage}
            disabled={isDetecting}
          />
          <View style={styles.buttonSpacing} />
          <Button
            title={isDetecting ? "Detecting..." : "Detect Objects (YOLO)"}
            onPress={detectObjectsWithYolo}
            disabled={isDetecting || !isModelLoaded}
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
  statusText: {
    marginBottom: 10,
    textAlign: "center" as const,
    fontStyle: "italic" as const,
    color: "#666",
  },
  buttonSpacing: {
    height: 10,
  },
};
