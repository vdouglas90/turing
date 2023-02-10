import 'package:chat_gpt_api/app/chat_gpt.dart';
import 'package:chat_gpt_api/app/model/data_model/completion/completion.dart';
import 'package:chat_gpt_api/app/model/data_model/completion/completion_request.dart';
import 'package:clip_shadow/clip_shadow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController listScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextEditingController textEditingController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  bool isListening = false;
  late stt.SpeechToText _speech;

  List<String> messagesChatGPT =["Olá mundo! Estou preparado para responder (quase) todas suas perguntas. O que deseja perguntar"];
  String token = "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";
  late final chatGpt;
  late bool available;

  @override
  void initState() {
    super.initState();
    chatGpt = ChatGPT.builder(
      token: token, // generate token from https://beta.openai.com/account/api-keys
    );
    _speech = stt.SpeechToText();
  }


  //Conversão da fala em texto
 Future<void> _listen()async{
    if(!isListening){
      bool available = await _speech.initialize(
        onStatus: (val)=>print("onStatus: $val"),
        onError: (val)=>print("onError: $val"),);
      if(available){
        setState(() {
          isListening = true;
        });
         _speech.listen(
           listenFor: Duration(seconds: 5),
           partialResults: false,
          onResult: (val) async{ //setState(() async {
            messagesChatGPT.add(val.recognizedWords);

            var content2 = await textCompletion(
                val.recognizedWords); // aqui seto a resposta do robô
            messagesChatGPT.add("${content2?.choices![0].text}");

            listScrollController.animateTo(
                0.0, duration: Duration(milliseconds: 300),
                curve: Curves.easeOut);
            setState(() {

            });
          }
        );
      }
    }
  }


  //Integração com ChatGPT
  Future<Completion?> textCompletion(String content) async {

    Completion? completion = await chatGpt.textCompletion(request: CompletionRequest(prompt: content, maxTokens: 256,),);

    if (kDebugMode) {
      print(completion?.choices);
    }
    return completion;
  }

  //envio da mensagem para o chat
  void onSendMessage(String content)async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (content.trim() != '') {
        textEditingController.clear();//primeiro seto a msg do usuario
        setState(()  {
          messagesChatGPT.add(content);
        });

        var content2 = await textCompletion(content); // aqui seto a resposta do robô
        setState(()  {
          messagesChatGPT.add("${content2?.choices![0].text}");
        });
        print("${content2?.choices![0].text}");
        listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);

  } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nada para enviar")));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MeuAppBar(context),
      key: _scaffoldKey,
      body: Container(
        padding: EdgeInsets.only(left: 5,top: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.indigo,
            ],
          ),
        ),
        child: Column(
          children: [

            // Mensagem do chatGPT e do Usuário se alternam
            Flexible(
              child: ListView.builder(
                controller: listScrollController,
                padding: EdgeInsets.all(1.0),
                reverse: true,
                itemCount: messagesChatGPT.length,
                itemBuilder: (BuildContext context, int index) {
                  int reversedIndex =messagesChatGPT.length - 1  - index;
                  return AnimatedAlign(
                    curve: Curves.fastOutSlowIn,
                    duration: reversedIndex == messagesChatGPT.length-1 ? Duration(seconds: 1) :  Duration(seconds: 0),
                    alignment:  reversedIndex.isEven ? Alignment.bottomLeft :Alignment.bottomRight,
                    child: Container(
                      width: MediaQuery.of(context).size.width*0.4,
                      margin: EdgeInsets.only(bottom: 10,left: 15,right: 15),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:reversedIndex.isEven ? Colors.lightBlueAccent[100] :Colors.greenAccent,
                        borderRadius:reversedIndex.isEven ? BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40), bottomRight:Radius.circular(40) ) : BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40), bottomLeft:Radius.circular(40) ) , //BorderRadius.circular(25),
                      ),
                      //duration: Duration(seconds: 1),
                      //curve: Curves.elasticIn,
                      child: Text(messagesChatGPT[reversedIndex]),
                    ),
                  );
                },
              ),
            ),

            //Container de envio das msgs
            Container(
              margin: EdgeInsets.only(bottom: 10,left: 15,right: 15),
              padding: EdgeInsets.all(10),
              height: MediaQuery.of(context).size.height*0.08,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.indigo,//Colors.indigo.withOpacity(f0.2),//
                borderRadius:BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AvatarGlow(
                    repeatPauseDuration: Duration(milliseconds: 100),
                    showTwoGlows: true,
                    endRadius: 40,
                    animate: isListening,
                    duration: Duration(milliseconds: 2000),
                    child: GestureDetector(child: Icon(isListening ? Icons.mic: Icons.mic_none,color: Colors.white,size: 30,),
                    onTap: _listen,
                      onDoubleTap: (){
                        _speech.stop();
                        isListening = false;
                        setState(() {

                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10,),
                  Flexible(
                    child: Container(
                      child: TextField(
                        onSubmitted: (value) {
                          onSendMessage(textEditingController.text);
                        },
                        style: TextStyle(color: Colors.white, fontSize:15.0),
                        controller: textEditingController,
                        decoration: InputDecoration.collapsed(
                            hintText:'Faça sua pergunta...',
                            hintStyle:  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) ,
                        focusNode: focusNode,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),color: Colors.white,
                  onPressed: (){
                     onSendMessage(textEditingController.text);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        child: Icon(Icons.restart_alt),
          onPressed: (){
          setState(()=> messagesChatGPT.removeRange(1,messagesChatGPT.length ));
          }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }
}


//Criação do AppBar personalizado
class MeuAppBar  extends StatefulWidget with PreferredSizeWidget{
  final BuildContext context;

  MeuAppBar(this.context);

  @override
  _MeuAppBarState createState() => _MeuAppBarState();

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size(double.infinity,MediaQuery.of(context).size.height*.12 );

}

class _MeuAppBarState extends State<MeuAppBar>with SingleTickerProviderStateMixin {
  late  AnimationController _animationController;
  late  Animation<double> _animation;

  void _animate(){
    _animationController.forward();
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));

    _animation = Tween<double>(begin: 0.7,end: 1.2).animate(_animationController);

    _animate();

    _animation.addStatusListener((status){
      if(status == AnimationStatus.completed){
        _animationController.reverse();
      }else if(status == AnimationStatus.dismissed){
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  //-------------------------------------------------------APPBAR------------------------------
  @override
  Widget build(BuildContext context) {

    return Container(
      child: ClipShadow(
        clipper: Clipper(),
        boxShadow: [
          BoxShadow(
            offset: Offset(0.0, 0.0),
            blurRadius: 20.0,
            spreadRadius: 20.0,
            color: Colors.grey,
          )
        ],
        child: Container(
          height: MediaQuery.of(context).size.height*.5, //aqui q altero tamanho do laranjinha, porém ele so vai até o máximo do tamanho do Size()
          //padding: EdgeInsets.only(left: 200,right: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.lightBlueAccent,
              Colors.indigo,
              //Colors.orangeAccent.shade100,
              //Theme.of(context).primaryColor
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          //padding: EdgeInsets.only(top:30 ,left: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width*.14,
                height: MediaQuery.of(context).size.height*.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                margin:  EdgeInsets.only(top: 30.0, right: 16.0),
                //padding: const EdgeInsets.all(3.0),
                child: ScaleTransition(
                  scale: _animation,
                  child: Container(
                    child: Icon(Icons.chat,size: 35,color: Colors.indigo[900],),
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  gradient: new LinearGradient(
                      colors: [
                        Colors.white10,
                        Colors.white,
                      ],
                      begin: const FractionalOffset(0.0, 0.0),
                      end: const FractionalOffset(1.0, 1.0),
                      stops: [0.0, 1.0],
                      tileMode: TileMode.clamp),
                ),
                width: MediaQuery.of(context).size.width*.6,
                height: 2.0,
              ),
              Padding(
                padding:  EdgeInsets.only(right: 10),
                child: Text("Chatbot" , style: TextStyle(fontSize: 15, color: Colors.white,fontWeight: FontWeight.bold,fontStyle: FontStyle.italic),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Cria
class Clipper extends CustomClipper<Path> {


  @override
  Path getClip(Size size) {
    var path = new Path();
    path.lineTo(1, size.height - 130); //path.lineTo(0, MediaQuery.of(context).size.height *.25 - 150);//
    var controllPoint = Offset(90, size.height);
    var endPoint = Offset(size.width / 1.2, size.height);
    path.quadraticBezierTo(
        controllPoint.dx, controllPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    //throw UnimplementedError();
    return true;
  }
}