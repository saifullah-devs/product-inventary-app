class UserEntity extends Equatable {
  final String id;
  final String email;
  final bool isAdmin;

  const UserEntity({required this.id, required this.email, required this.isAdmin});

  @override
  List<Object?> get props => [id, email, isAdmin];
}