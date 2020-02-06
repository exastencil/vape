# Vape (is a Work in Progress)

The functional web micro-framework!

### What does it do?

It helps you structure your code into units that handle HTTP web requests.
Each of these are called **handlers**. They can then be compiled and deployed
individually, or linked to a router and deployed together.

### Why would you want to do that?

This structure opens up some opportunities. Individual **handlers** can run in
their own lambda function or similar serverless environment. You can have quick
deploys of individual **handlers** or do checksum diffing to deploy only ones
that have changed. In more advanced cases you could group **handlers** together
and scale groups vertically or horizontally to accommodate your traffic.

### Okay, but that leaves a lot for me to do.

That is not a question, but yes. Vape will try to bring all the tools together
to help you route handlers, develop locally and compile **handlers** in the
configuration of your choosing.
