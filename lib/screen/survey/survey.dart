import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/survey/survey_thankyou.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SurveyPage extends StatefulWidget {
  static const String tag = 'survey_step_1';

  const SurveyPage({Key? key}) : super(key: key);
  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final PageController _pageController = PageController();
  int _currentPage = 1;
  String? _surveyAnswer;

  _SurveyPageState();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getCloseAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _currentPage == 1
                  ? "How did you hear about Autonomy? "
                  : "Which NFT marketplace? ",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 40.0),
            Expanded(
                child: PageView(
              /// [PageView.scrollDirection] defaults to [Axis.horizontal].
              /// Use [Axis.vertical] to scroll vertically.
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: <Widget>[
                _page1(context),
                _page2(context),
              ],
            )),
            AuFilledButton(
                text: "Continue",
                enabled: _surveyAnswer != null,
                onPress: () {
                  const onboardingSurveyKey = "onboarding_survey";
                  injector<AWSService>().storeEventWithDeviceData(
                      onboardingSurveyKey,
                      message: _surveyAnswer);
                  injector<ConfigurationService>()
                      .setFinishedSurvey(onboardingSurveyKey);
                  Navigator.of(context)
                      .pushReplacementNamed(SurveyThankyouPage.tag);
                }),
            SizedBox(height: 27.0),
          ],
        ),
      ),
    );
  }

  Widget _page1(BuildContext context) {
    const surveyItems = [
      "Word of mouth",
      "Feral File Discord",
      "Feral File newsletter",
      "NFT marketplace"
    ];

    return SurveyQuestionarePage(
      questionItems: surveyItems,
      onItemSelected: (index) {
        if (index == 3) {
          _moveToPage(2);
        } else {
          setState(() {
            _surveyAnswer = surveyItems[index];
          });
        }
      },
      onOtherItemSelected: (otherItem) {
        setState(() {
          _surveyAnswer = otherItem;
        });
      },
    );
  }

  Widget _page2(BuildContext context) {
    const surveyItems = [
      "OpenSea",
      "objkt.com",
      "fxhash",
    ];

    const marketplacePrefix = "marketplace: ";

    return SurveyQuestionarePage(
      questionItems: surveyItems,
      onItemSelected: (index) {
        setState(() {
          _surveyAnswer = marketplacePrefix + surveyItems[index];
        });
      },
      onOtherItemSelected: (otherItem) {
        setState(() {
          _surveyAnswer = marketplacePrefix + otherItem;
        });
      },
    );
  }

  Future<void> _moveToPage(int page) async {
    await _pageController.nextPage(
        duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
    setState(() {
      _currentPage = page;
    });
  }
}

class SurveyQuestionarePage extends StatefulWidget {
  final List<String> questionItems;
  final WidgetBuilder? header;
  final Function(String)? onOtherItemSelected;
  final Function(int)? onItemSelected;

  SurveyQuestionarePage(
      {Key? key,
      required this.questionItems,
      this.header,
      this.onItemSelected,
      this.onOtherItemSelected})
      : super(key: key);
  @override
  State<SurveyQuestionarePage> createState() => _SurveyQuestionarePageState();
}

class _SurveyQuestionarePageState extends State<SurveyQuestionarePage> {
  int selection = -1;
  final TextEditingController _feedbackTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final focusNode = FocusNode();

  _SurveyQuestionarePageState();
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (widget.header != null)
          SliverToBoxAdapter(child: widget.header!(context)),
        SliverList(
            delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = widget.questionItems[index];

            return GestureDetector(
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Color.fromRGBO(227, 227, 227, 1)))),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                        item,
                        style: appTextTheme.headline4,
                        overflow: TextOverflow.ellipsis,
                      )),
                      SvgPicture.asset(selection == index
                          ? 'assets/images/radio_selected.svg'
                          : 'assets/images/radio_unselected.svg')
                    ],
                  )),
              onTap: () {
                setState(() {
                  selection = index;
                });
                if (widget.onItemSelected != null) {
                  widget.onItemSelected!(index);
                }
                focusNode.unfocus();
              },
            );
          },
          childCount: widget.questionItems.length,
        )),
        SliverToBoxAdapter(
          child: Container(
              padding: EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: selection == widget.questionItems.length
                              ? Colors.black
                              : Color.fromRGBO(227, 227, 227, 1)))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: appTextTheme.headline4,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: "Other",
                        hintMaxLines: 1,
                        hintStyle: appTextTheme.headline4?.copyWith(
                            color: selection == widget.questionItems.length
                                ? Colors.grey
                                : null),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.done,
                      controller: _feedbackTextController,
                      onTap: () {
                        setState(() {
                          selection = widget.questionItems.length;
                        });
                      },
                      onEditingComplete: () {
                        focusNode.unfocus();
                        if (widget.onItemSelected != null) {
                          widget.onOtherItemSelected!(
                              _feedbackTextController.text);
                        }
                      },
                    ),
                  ),
                  GestureDetector(
                    child: SvgPicture.asset(
                        selection == widget.questionItems.length
                            ? 'assets/images/radio_selected.svg'
                            : 'assets/images/radio_unselected.svg'),
                    onTap: () {
                      setState(() {
                        selection = widget.questionItems.length;
                      });
                      if (_feedbackTextController.text.isEmpty) {
                        focusNode.requestFocus();
                      } else if (widget.onItemSelected != null) {
                        widget
                            .onOtherItemSelected!(_feedbackTextController.text);
                      }
                    },
                  )
                ],
              )),
        ),
        SliverPadding(padding: EdgeInsets.only(bottom: 6))
      ],
    );
  }
}
