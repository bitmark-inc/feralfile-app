import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:floor/floor.dart';

@dao
abstract class CanvasDeviceDao {
  @Query('SELECT * FROM CanvasDevice')
  Future<List<CanvasDevice>> getCanvasDevices();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCanvasDevice(CanvasDevice canvasDevice);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCanvasDevices(List<CanvasDevice> canvasDevices);

  @update
  Future<void> updateCanvasDevice(CanvasDevice canvasDevice);

  @delete
  Future<void> deleteCanvasDevice(CanvasDevice canvasDevice);

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

  @Query('UPDATE Scene SET metadata = :metadata WHERE id = :id')
  Future<void> updateSceneMetadata(String id, String metadata);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScene(Scene scene);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScenes(List<Scene> scenes);

  @update
  Future<void> updateScene(Scene scene);

  @Query('DELETE FROM Scene')
  Future<void> removeAll();
}
