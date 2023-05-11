import 'package:autonomy_flutter/database/entity/canvas_device.dart';
import 'package:floor/floor.dart';

@dao
abstract class CanvasDeviceDao {
  @Query('SELECT * FROM CanvasDevice')
  Future<List<CanvasDevice>> getCanvasDevices();

  @Query(
      'UPDATE CanvasDevice SET lastScenePlayed = :lastScenePlayed WHERE id = :id')
  Future<void> setLastScenePlayed(String id, String lastScenePlayed);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCanvasDevice(CanvasDevice canvasDevice);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCanvasDevices(List<CanvasDevice> canvasDevices);

  @Query('DELETE FROM CanvasDevice')
  Future<void> removeAll();
}

@dao
abstract class SceneDao {
  @Query('SELECT * FROM Scene')
  Future<List<Scene>> getScenes();

  @Query('SELECT * FROM Scene WHERE deviceId = :deviceId')
  Future<List<Scene>> getScenesByDeviceId(String deviceId);

  @Query('SELECT * FROM Scene WHERE id = :id')
  Future<Scene?> getSceneById(String id);

  @Query(
      'UPDATE Scene SET metadata = :metadata WHERE id = :id')
  Future<void> updateSceneMetadata(String id, String metadata);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScene(Scene scene);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScenes(List<Scene> scenes);

  @Query('DELETE FROM Scene')
  Future<void> removeAll();
}
