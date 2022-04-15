# Self-winder
A simple script to automatically maintain a reverse SSH tunnel, re-establishing the SSH connection if failed.

## Motivation

In order to access servers within intranets with a public address, we currently adopt 
reverse SSH as work-around. However, the SSH connection session brokes easily 
due to various unexpected network events.

### Unreliable Tunneler
The liveness of the *tunneler*, a public-accessible VM on ali-cloud, is rather unreliable.
Sometimes the intranet servers can't reach the *tunneler* to maintain the reverse 
SSH session, leading to a connection failure.

### **Autossh** Not Working

## Objective

### Fault-tolerant SSH Session

Rely on periodical SSH re-establishment to resist potential *tunneler* failure.

### QoS Evaluation

Help troubleshoot the root cause of SSH disconnection.

### Anomaly Reports

Even with automatic session recovery, the reverse SSH connection could still fails 
due to other unexpected reasons. As a result, the system should notify the operator 
once it can't recover the reverse SSH session.

## Quick Start
