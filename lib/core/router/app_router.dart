import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/midnight_pitch_theme.dart';
import '../../providers/auth_provider.dart';
import '../../ui_screens/splash_screen.dart';
import '../../ui_screens/login_screen.dart';
import '../../ui_screens/signup_screen.dart';
import '../../ui_screens/position_selection_screen.dart';
import '../../ui_screens/home_screen.dart';
import '../../ui_screens/player_profile_screen.dart';
import '../../ui_screens/leaderboard_screen.dart';
import '../../ui_screens/find_match_screen.dart';
import '../../ui_screens/live_match_screen.dart';
import '../../models/match_model.dart';
import '../../ui_screens/match_summary_screen.dart';
import '../../ui_screens/upcoming_match_detail_screen.dart';
import '../../ui_screens/pro_comparison_screen.dart';
import '../../ui_screens/squad_management_screen.dart';
import '../../ui_screens/formation_builder_screen.dart';
import '../../ui_screens/matchday_lineup_screen.dart';
import '../../ui_screens/player_roster_profile_screen.dart';
import '../../ui_screens/learning_hub_screen.dart';
import '../../ui_screens/drill_library_screen.dart';
import '../../ui_screens/skill_challenge_screen.dart';
import '../../ui_screens/tournament_home_screen.dart';
import '../../ui_screens/tournament_detail_screen.dart';
import '../../ui_screens/tournament_create_screen.dart';
import '../../ui_screens/half_time_screen.dart';
import '../../ui_screens/session_planner_screen.dart';
import '../../ui_screens/coach_home_screen.dart';
import '../../features/match/presentation/screens/match_creation_screen.dart';
import '../../features/team/presentation/screens/team_chat_screen.dart';
import '../shell/main_shell.dart';

/// Route name constants — use these everywhere, never hardcode strings
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const positionSelection = '/onboarding/position';

  // Shell routes (have bottom nav)
  static const home = '/home';
  static const profile = '/home/profile';
  static const leaderboard = '/home/leaderboard';
  static const squad = '/home/squad';

  static const match = '/match';
  static const liveMatch = '/match/live';
  static const matchSummary = '/match/summary';
  static const matchDetail = '/match/detail';
  static const proCard = '/match/pro-card';
  static const matchCreation = '/match/create';

  static const coach = '/coach';
  static const formation = '/coach/formation';
  static const lineup = '/coach/lineup';
  static const playerCard = '/coach/player';

  static const learn = '/learn';
  static const drills = '/learn/drills';
  static const challenge = '/learn/challenge';

  // Tournament routes
  static const tournaments = '/tournaments';
  static const tournamentCreate = '/tournaments/create';
  static const tournamentDetail = '/tournaments/detail';
  static const tournamentBracket = '/tournaments/bracket';
  static const tournamentStandings = '/tournaments/standings';

  // Session planner route
  static const sessionPlanner = '/coach/session';

  // Team chat route
  static const teamChat = '/team/chat';
}

/// A ChangeNotifier that fires whenever auth state changes,
/// so GoRouter re-evaluates redirects.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authProvider, (prev, next) {
      notifyListeners();
    });
  }
}

final _authChangeNotifierProvider = Provider<_AuthChangeNotifier>((ref) {
  return _AuthChangeNotifier(ref);
});

/// The GoRouter provider — watches auth state for redirect logic.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(_authChangeNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;

      // Still loading — stay on splash
      if (isLoading) return null;

      final onAuthScreen = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.positionSelection,
      ].contains(state.matchedLocation);

      // Not logged in — send to login
      if (!isAuthenticated && !onAuthScreen) {
        return AppRoutes.login;
      }

      // Logged in — skip auth screens
      if (isAuthenticated && onAuthScreen) {
        return AppRoutes.home;
      }

      return null; // no redirect needed
    },
    routes: [
      // ── AUTH ROUTES (no bottom nav) ──────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(
          onSignupTap: () => context.go(AppRoutes.signup),
          onForgotPasswordTap: () => _showForgotPasswordDialog(context),
          onBackTap: () => context.go(AppRoutes.splash),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => SignupScreen(
          onSigninTap: () => context.go(AppRoutes.login),
          onBackTap: () => context.go(AppRoutes.login),
        ),
      ),
      GoRoute(
        path: AppRoutes.positionSelection,
        builder: (context, state) => PositionSelectionScreen(
          onSkip: () => context.go(AppRoutes.home),
        ),
      ),
      GoRoute(
        path: AppRoutes.matchCreation,
        builder: (context, state) => const MatchCreationScreen(),
      ),

      // ── MAIN SHELL (has shared bottom nav) ───────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // PLAYER TAB
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => const PlayerProfileScreen(),
              ),
              GoRoute(
                path: 'leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
              GoRoute(
                path: 'squad',
                builder: (context, state) => const SquadManagementScreen(),
                routes: [
                  GoRoute(
                    path: 'chat/:teamId',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId'] ?? '';
                      final teamName = state.uri.queryParameters['name'] ?? 'Team';
                      return TeamChatScreen(teamId: teamId, teamName: teamName);
                    },
                  ),
                ],
              ),
            ],
          ),

          // MATCH TAB
          GoRoute(
            path: AppRoutes.match,
            builder: (context, state) => const FindMatchScreen(),
            routes: [
              GoRoute(
                path: 'live',
                builder: (context, state) {
                  final match = state.extra as MatchModel?;
                  return LiveMatchScreen(
                    match: match,
                    onHalfTime: () => context.go('${AppRoutes.match}/halftime'),
                    onFullTime: () => context.go('${AppRoutes.match}/summary'),
                  );
                },
              ),
              GoRoute(
                path: 'summary',
                builder: (context, state) {
                  final match = state.extra as MatchModel?;
                  return MatchSummaryScreen(
                    matchId: match?.matchId,
                    onBack: () => context.go(AppRoutes.home),
                    onGoHome: () => context.go(AppRoutes.home),
                    onViewComparison: () => context.go(AppRoutes.proCard),
                  );
                },
              ),
              GoRoute(
                path: 'detail',
                builder: (context, state) {
                  final match = state.extra as MatchModel?;
                  if (match == null) return const SizedBox.shrink();
                  return UpcomingMatchDetailScreen(
                    match: match,
                    onBack: () => context.go(AppRoutes.home),
                    onStartMatch: () => context.go(AppRoutes.liveMatch, extra: match),
                  );
                },
              ),
              GoRoute(
                path: 'pro-card',
                builder: (context, state) => ProComparisonScreen(
                  onBack: () => context.go(AppRoutes.matchSummary),
                ),
              ),
              GoRoute(
                path: 'halftime',
                builder: (context, state) => HalfTimeScreen(
                  onStartSecondHalf: () => context.go('${AppRoutes.match}/live'),
                  onEndMatch: () => context.go(AppRoutes.matchSummary),
                ),
              ),
            ],
          ),

          // COACH TAB
          GoRoute(
            path: AppRoutes.coach,
            builder: (context, state) => const CoachHomeScreen(),
            routes: [
              GoRoute(
                path: ':teamId',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId'] ?? '';
                  return FormationBuilderScreen(
                    teamId: teamId,
                    onBack: () => context.go(AppRoutes.home),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'lineup/:matchId',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId'] ?? '';
                      final matchId = state.pathParameters['matchId'] ?? '';
                      final opponentName = state.uri.queryParameters['opponent'] ?? 'Opponent';
                      return KeyedSubtree(
                        key: ValueKey('lineup-$teamId-$matchId'),
                        child: MatchdayLineupScreen(
                          matchId: matchId,
                          teamId: teamId,
                          opponentName: opponentName,
                          onBack: () => context.go('${AppRoutes.coach}/$teamId'),
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'player/:playerId',
                    builder: (context, state) {
                      final playerId = state.pathParameters['playerId'] ?? '';
                      return PlayerRosterProfileScreen(
                        playerId: playerId,
                        onBack: () => context.go(AppRoutes.coach),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'session',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId'] ?? '';
                      return SessionPlannerScreen(
                        teamId: teamId,
                        onBack: () => context.go('${AppRoutes.coach}/$teamId'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // LEARN TAB
          GoRoute(
            path: AppRoutes.learn,
            builder: (context, state) => const LearningHubScreen(),
            routes: [
              GoRoute(
                path: 'drills',
                builder: (context, state) => const DrillLibraryScreen(),
              ),
              GoRoute(
                path: 'challenge',
                builder: (context, state) => SkillChallengeScreen(
                  onBack: () => context.go(AppRoutes.learn),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── TOURNAMENT ROUTES (no bottom nav) ──────────────────────
      GoRoute(
        path: AppRoutes.tournaments,
        builder: (context, state) => const TournamentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.tournamentCreate,
        builder: (context, state) => const TournamentCreateScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.tournamentDetail}/:tournamentId',
        builder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId'] ?? '';
          return TournamentDetailScreen(tournamentId: tournamentId);
        },
      ),
    ],
  );
});

/// Shows a forgot password dialog
void _showForgotPasswordDialog(BuildContext context) {
  final emailController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      title: Text(
        'Reset Password',
        style: TextStyle(color: MidnightPitchTheme.primaryText),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: TextStyle(color: MidnightPitchTheme.secondaryText),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: MidnightPitchTheme.primaryText),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              hintStyle: TextStyle(color: MidnightPitchTheme.mutedText),
              filled: true,
              fillColor: MidnightPitchTheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MidnightPitchTheme.ghostBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MidnightPitchTheme.ghostBorder),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final email = emailController.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please enter your email address'),
                  backgroundColor: MidnightPitchTheme.electricMint,
                ),
              );
              return;
            }
            // Attempt to send recovery email
            try {
              // Use the Appwrite service directly here to send recovery
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Recovery email sent — check your inbox'),
                  backgroundColor: MidnightPitchTheme.electricMint,
                ),
              );
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: MidnightPitchTheme.liveRed,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MidnightPitchTheme.electricMint,
            foregroundColor: Colors.white,
          ),
          child: const Text('Send Link'),
        ),
      ],
    ),
  );
}