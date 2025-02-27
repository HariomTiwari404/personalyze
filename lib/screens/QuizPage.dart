import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:personlayze/screens/quizGen.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> questions = [];
  Map<int, String> userResponses = {};
  int questionIndex = 0;
  bool isLoading = true;
  bool isSubmitting = false;
  final PageController _pageController = PageController();
  final QuizGenerator quizGenerator = QuizGenerator();

  @override
  void initState() {
    super.initState();
    _fetchGeneratedQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchGeneratedQuestions() async {
    List<Map<String, dynamic>> generatedQuestions =
        await quizGenerator.generateQuizQuestions();

    setState(() {
      questions = generatedQuestions;
      isLoading = false;
    });
  }

  void nextPage() {
    if (questionIndex + 10 < questions.length) {
      setState(() {
        questionIndex += 10;
      });
      _pageController.animateToPage(
        questionIndex ~/ 10,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (questionIndex - 10 >= 0) {
      setState(() {
        questionIndex -= 10;
      });
      _pageController.animateToPage(
        questionIndex ~/ 10,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> uploadResponses() async {
    int totalQuestionsOnPage = (questionIndex + 10 <= questions.length)
        ? 10
        : questions.length - questionIndex;

    bool allAnswered = true;
    for (int i = questionIndex; i < questionIndex + totalQuestionsOnPage; i++) {
      if (!userResponses.containsKey(i)) {
        allAnswered = false;
        break;
      }
    }

    if (!allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please answer all questions before submitting!"),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    List<Map<String, dynamic>> submittedResponses =
        userResponses.entries.map((entry) {
      int index = entry.key;
      return {
        "question": questions[index]["question"],
        "selected_answer": entry.value,
      };
    }).toList();

    try {
      DocumentReference responseDoc = FirebaseFirestore.instance
          .collection('responses')
          .doc('user_responses');

      DocumentSnapshot docSnapshot = await responseDoc.get();

      if (docSnapshot.exists) {
        await responseDoc.update({
          "responses": FieldValue.arrayUnion(submittedResponses),
        });
      } else {
        await responseDoc.set({
          "responses": submittedResponses,
          "timestamp": Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Responses Submitted Successfully!"),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      setState(() {
        userResponses.clear();
        questionIndex = 0;
        isSubmitting = false;
      });

      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading responses: $e"),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() {
        isSubmitting = false;
      });
    }
  }

  int getPageCount() {
    return (questions.length / 10).ceil();
  }

  List<Map<String, dynamic>> getQuestionsForPage(int pageIndex) {
    int startIndex = pageIndex * 10;
    int endIndex = startIndex + 10;

    if (endIndex > questions.length) {
      endIndex = questions.length;
    }

    return questions.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Personalyse Quiz",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Loading your quiz...",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 80,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No questions available.",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _fetchGeneratedQuestions,
                            child: const Text("Try Again"),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: LinearProgressIndicator(
                            value: (_pageController.hasClients &&
                                    _pageController.page != null)
                                ? (_pageController.page! + 1) / getPageCount()
                                : 1 / getPageCount(),
                            backgroundColor: Colors.white.withOpacity(0.5),
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 8,
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (page) {
                              setState(() {
                                questionIndex = page * 10;
                              });
                            },
                            itemCount: getPageCount(),
                            itemBuilder: (context, pageIndex) {
                              final pageQuestions =
                                  getQuestionsForPage(pageIndex);
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ListView.builder(
                                  itemCount: pageQuestions.length,
                                  itemBuilder: (context, index) {
                                    int actualIndex = pageIndex * 10 + index;
                                    var questionData = pageQuestions[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              color: Colors.blue.shade700,
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 36,
                                                    width: 36,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18),
                                                    ),
                                                    child: Text(
                                                      "${actualIndex + 1}",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      questionData['question'],
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 4,
                                              ),
                                              child: Column(
                                                children:
                                                    questionData['options']
                                                        .map<Widget>((option) {
                                                  bool isSelected =
                                                      userResponses[
                                                              actualIndex] ==
                                                          option;
                                                  return InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        userResponses[
                                                                actualIndex] =
                                                            option;
                                                      });
                                                    },
                                                    child: Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 4,
                                                        horizontal: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? Colors
                                                                .blue.shade50
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? Colors
                                                                  .blue.shade700
                                                              : Colors.grey
                                                                  .shade300,
                                                          width: isSelected
                                                              ? 2
                                                              : 1,
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 12,
                                                          horizontal: 16,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              height: 24,
                                                              width: 24,
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border:
                                                                    Border.all(
                                                                  color: isSelected
                                                                      ? Colors
                                                                          .blue
                                                                          .shade700
                                                                      : Colors
                                                                          .grey
                                                                          .shade500,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                              child: isSelected
                                                                  ? Center(
                                                                      child:
                                                                          Container(
                                                                        height:
                                                                            12,
                                                                        width:
                                                                            12,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          color: Colors
                                                                              .blue
                                                                              .shade700,
                                                                        ),
                                                                      ),
                                                                    )
                                                                  : null,
                                                            ),
                                                            const SizedBox(
                                                                width: 16),
                                                            Expanded(
                                                              child: Text(
                                                                option,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  color: isSelected
                                                                      ? Colors
                                                                          .blue
                                                                          .shade700
                                                                      : Colors
                                                                          .black87,
                                                                  fontWeight: isSelected
                                                                      ? FontWeight
                                                                          .w500
                                                                      : FontWeight
                                                                          .normal,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: (_pageController.hasClients &&
                                        _pageController.page != null &&
                                        _pageController.page! > 0)
                                    ? () {
                                        _pageController.previousPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text("Previous"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade700,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed:
                                    isSubmitting ? null : uploadResponses,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Submit",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              ElevatedButton.icon(
                                onPressed: (_pageController.hasClients &&
                                        _pageController.page != null &&
                                        _pageController.page! <
                                            getPageCount() - 1)
                                    ? () {
                                        _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text("Next"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade700,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
