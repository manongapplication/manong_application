class StepFlow {
  final String id;
  final List<String> stepLabels;
  
  const StepFlow({
    required this.id,
    required this.stepLabels,
  });
  
  int get totalSteps => stepLabels.length;
}