import 'package:appwrite/appwrite.dart';
import 'environment.dart';

final Client client = Client()
  .setProject(Environment.appwriteProjectId)
  .setEndpoint(Environment.appwritePublicEndpoint);
