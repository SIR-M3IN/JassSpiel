import 'package:flutter/material.dart';

class Start extends StatelessWidget {
  const Start({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            buildRoomWidget('Room 1', 5, 0),
            buildRoomWidget('Room 1', 5, 0),
            buildRoomWidget('Room 1', 5, 0),
            buildRoomWidget('Room 1', 5, 0),
            buildRoomWidget('Room 1', 5, 0),
            ],
          ),
        ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {

          },
          tooltip: 'Create Room',
          child: Icon(Icons.add),
        ),
    );
  }
  Widget buildRoomWidget(String roomName, int parcipants, int roomId) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room: $roomName',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                createRoomWidget();
              },
              child: Text('Enter Room'),
            ),
          ],
        ),
      ),
    );
  }
  Widget createRoomWidget() {
    return Card(
    margin: EdgeInsets.all(16),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
      TextField(
        decoration: InputDecoration(
          labelText: 'Room Name',
          border: OutlineInputBorder(),
        ),
      ),
      SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
        onPressed: () {
          // Logic for creating the room
        },
        child: Text('Create'),
          ),
          ElevatedButton(
        onPressed: () {
          // Logic for canceling the action
        },
        child: Text('Cancel'),
          ),
        ],
      ),
        ],
      ),
    ),
    );
}
}