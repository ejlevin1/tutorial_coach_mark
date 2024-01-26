abstract class InitActionTarget {
  Future<bool> init();
}

abstract class PreActionTarget {
  Future<void> pre();
}

abstract class PostActionTarget {
  Future<void> post();
}
