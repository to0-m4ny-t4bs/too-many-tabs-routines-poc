enum DestinationBucket {
  backlog('backlog'),
  archives('archives');

  const DestinationBucket(this.destination);

  final String destination;
}
