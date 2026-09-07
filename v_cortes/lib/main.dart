import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        
        appBar: AppBar(

          backgroundColor: const Color.fromARGB(255, 99, 28, 28), 

          leading: IconButton(icon: const Icon(Icons.arrow_drop_down),
          color: Colors.white,
          onPressed: () {
            
          },),


          title: const Text('Canción/video',
          style: TextStyle(color:Colors.white),), 

          actions: [

          IconButton(icon: const Icon(Icons.more_vert),
          color: Colors.white,
          onPressed: () {
            
          },),


          ],
        ),
        
        body: SingleChildScrollView(
          child: Column(
            children: [
  

              Container(
                height: 500,
                width: double.infinity,
                padding: const EdgeInsets.only(left: 40.0, right:40.0, top:80.0, bottom:80.0,),
                color:  const Color.fromARGB(255, 99, 28, 28), 

               child:Container(
                color: Colors.white,

               
               )
              ),

              SizedBox(height: 4.0),

                Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.only(left: 40.0, right:40.0),
                color:  const Color.fromARGB(255, 99, 28, 28), 
                 child: const Center (
                        child: Text('Cosas Imposibles',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                        ),
                      ),

              ),
                 SizedBox(height: 4.0),

                 Container(
                height: 80,
                width: double.infinity,
                padding: const EdgeInsets.only(left: 40.0, right:40.0, top:39.0, bottom:38.0),
                color:  const Color.fromARGB(255, 99, 28, 28), 

                 child:Container(
                color:  const Color.fromARGB(255, 159, 159, 159),

               
               )
                

              ),
                 SizedBox(height: 4.0),

                Container(
                height: 200,
                width: double.infinity,
                color:  const Color.fromARGB(255, 99, 28, 28), 

              ),

             

            ],



          ),
        ),
       
        bottomNavigationBar: BottomNavigationBar(

          

          backgroundColor: const Color.fromARGB(255, 120, 57, 44), 
          selectedItemColor: const Color.fromARGB(255, 159, 159, 159),
          unselectedItemColor: Color.fromARGB(255,255,255,255),

          items: const [

            

            BottomNavigationBarItem(icon:Icon(null),
            label: 'Siguientes'),
  

            BottomNavigationBarItem(icon:Icon(null),
            label: 'Letra',),

            BottomNavigationBarItem(icon:Icon(null),
            label: 'Similares',),


          ] ),
        


        
        ),
    );
  }
}
