# Shuei Server 守衛サーバ 

## Development info and goals
### Database
We're currently using SQLite3
- [x] Connects
- [x] Create table
- [x] Insert row
- [ ] Select
What do we need to store:
* Slave devices: Hardware UUID, Name, current IP, current GPIO State
* General log: Log-id, Dev UUID, Timestamp, Priority, Message
### API
#### Slave
Slave devices sends its status info in a json format to server. Server responds with an OK or command.
If no response from server is got in some attempts, it will get into _Alert Mode_.
This JSON table provides:
* Device UUID
* Priority (as systemd does)
* Message
