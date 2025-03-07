# Operations

This folder contains all the operations to be used throughout the application  

## Example

```Future<void> addNote(String note) {
    return notes.add({
      'note': note,
      'createdAt': Timestamp.now(),
    });
  }```
