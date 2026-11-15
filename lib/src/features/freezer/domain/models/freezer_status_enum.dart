enum FreezerStatusEnum {
  idle,
  cooling,
  doorOpen,
  ready,
  feedbackPending;

  bool get isCooling => this == FreezerStatusEnum.cooling;
  bool get isDoorOpen => this == FreezerStatusEnum.doorOpen;
  bool get isReady => this == FreezerStatusEnum.ready;
  bool get isFeedbackPending => this == FreezerStatusEnum.feedbackPending;
}

