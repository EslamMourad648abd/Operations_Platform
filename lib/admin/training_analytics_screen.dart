import 'package:bbc_api_tool/admin/services/training_analytics_service.dart';
import 'package:flutter/material.dart';

import '../modules/training/models/agent_training_analytics_model.dart';

import 'agent_training_details_screen.dart';

class TrainingAnalyticsScreen extends StatefulWidget {
  const TrainingAnalyticsScreen({
    super.key,
  });

  @override
  State<TrainingAnalyticsScreen> createState() =>
      _TrainingAnalyticsScreenState();
}

class _TrainingAnalyticsScreenState
    extends State<TrainingAnalyticsScreen> {
  // ============================================================
  // SERVICE
  // ============================================================

  final TrainingAnalyticsService service =
  TrainingAnalyticsService();

  // ============================================================
  // STATE
  // ============================================================

  List<AgentTrainingAnalyticsModel> agents = [];

  bool loading = true;

  bool refreshing = false;

  String? error;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadAnalytics();
  }

  // ============================================================
  // INITIAL / CACHED LOAD
  // ============================================================

  Future<void> _loadAnalytics() async {
    try {
      final result =
      await service.getAllTraineeAnalytics();

      if (!mounted) return;

      setState(() {
        agents = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      debugPrint(
        'ANALYTICS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });

      if (agents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load analytics',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // FORCE REFRESH
  // ============================================================

  Future<void> _refreshAnalytics() async {
    if (refreshing) return;

    setState(() {
      refreshing = true;
    });

    try {
      final result =
      await service.getAllTraineeAnalytics(
        forceRefresh: true,
      );

      if (!mounted) return;

      setState(() {
        agents = result;
        refreshing = false;
        error = null;
      });
    } catch (e) {
      debugPrint(
        'ANALYTICS REFRESH ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        refreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to refresh analytics',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ANALYTICS CARD
  // ============================================================

  Widget _analyticsCard(
      AgentTrainingAnalyticsModel agent,
      ) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(16),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AgentTrainingDetailsScreen(
                  agent: agent,
                ),
          ),
        );
      },

      child: Card(
        elevation: 3,

        margin: const EdgeInsets.only(
          bottom: 16,
        ),

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),

        child: Padding(
          padding:
          const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // ==================================================
              // USER HEADER
              // ==================================================

              Row(
                children: [
                  CircleAvatar(
                    radius: 25,

                    backgroundColor:
                    const Color(
                      0xff003366,
                    ),

                    child: Text(
                      agent.userName.isNotEmpty
                          ? agent.userName[0]
                          .toUpperCase()
                          : '?',

                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 15,
                  ),

                  Expanded(
                    child: Text(
                      agent.userName,

                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // STATISTICS
              // ==================================================

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [
                  _stat(
                    'Courses',
                    agent.totalCourses
                        .toString(),
                  ),

                  _stat(
                    'Completed',
                    agent.completedCourses
                        .toString(),
                  ),

                  _stat(
                    'Progress',
                    '${agent.overallProgress.toStringAsFixed(0)}%',
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // QUIZ SCORE
              // ==================================================

              Text(
                'Average Quiz Score',

                style: TextStyle(
                  color:
                  Colors.grey.shade700,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              LinearProgressIndicator(
                value:
                (agent.averageQuizScore /
                    100)
                    .clamp(0.0, 1.0),

                minHeight: 10,
              ),

              const SizedBox(
                height: 8,
              ),

              Align(
                alignment:
                Alignment.centerRight,

                child: Text(
                  '${agent.averageQuizScore.toStringAsFixed(1)}%',

                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,

                    color:
                    Color(0xff003366),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT
  // ============================================================

  Widget _stat(
      String title,
      String value,
      ) {
    return Column(
      children: [
        Text(
          value,

          style:
          const TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
            color:
            Color(0xff003366),
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          title,

          style:
          const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,

      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(
            height: 250,
          ),

          Center(
            child: Text(
              'No trainee data available',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState() {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,

      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        children: [
          const SizedBox(
            height: 180,
          ),

          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),

          const SizedBox(
            height: 16,
          ),

          const Center(
            child: Text(
              'Failed to load analytics',
              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 30,
            ),

            child: Text(
              error ?? '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Center(
            child: ElevatedButton(
              onPressed:
              _loadAnalytics,
              child:
              const Text(
                'Try Again',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),

      appBar: AppBar(
        title:
        const Text(
          'Training Analytics',
        ),

        actions: [
          IconButton(
            tooltip:
            'Refresh analytics',

            onPressed:
            refreshing
                ? null
                : _refreshAnalytics,

            icon: refreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: loading

      // ====================================================
      // FIRST LOAD
      // ====================================================

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

      // ====================================================
      // ERROR WITH NO DATA
      // ====================================================

          : error != null &&
          agents.isEmpty

          ? _errorState()

      // ==================================================
      // EMPTY
      // ==================================================

          : agents.isEmpty

          ? _emptyState()

      // ==============================================
      // DATA
      // ==============================================

          : RefreshIndicator(
        onRefresh:
        _refreshAnalytics,

        child:
        ListView.builder(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(
            20,
          ),

          itemCount:
          agents.length,

          itemBuilder:
              (
              context,
              index,
              ) {
            return _analyticsCard(
              agents[index],
            );
          },
        ),
      ),
    );
  }
}