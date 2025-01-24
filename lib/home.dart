import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text("Hello World!", style: theme.textTheme.displayMedium,),
        // this looks like shit on nvim treesitter
        Text("""
You can test out the GD Devtools Protocol methods in this application!
To get started, select a domain in the left navigation bar, pick a method, set parameters (if any) and execute!


There's also events that you can listen to whenever its fired. Simply scroll to the events section, listen to that event and wait!
        """.trim(), 
        softWrap: true,),
      ],
    );
  }

}
