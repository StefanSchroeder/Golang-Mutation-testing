
Adventures in Golang: Mutation testing in Go
============================================

I always thought that error seeding and mutation testing are a cool idea. You intentionally introduce an error into your source code and see what happens when you run your tests. The theory behind error seeding also claims to be able to predict the total number of errors in a body of code, but I am interested for another reason. Error seeding allows me to enhance the coverage and quality of my unit tests.

The plan works like this:

	Make an atomic change to the source code.
	Run the tests.

If the test reports a 'fail' that's good, because the test actually caught the patch. But if the test runs 'ok', this means that the modification - representing a coding error - was not detected! Actually this procedure is called 'Mutation testing' in the literature instead of 'Error seeding'.

Now: manual error seeding is cumbersome and error-prone,  difficult to manage without the help of specialized tools. 

The obvious solution is to patch the source code automatically with a tool. This allows to patch code effectively, reproducibly and using a large number of strategies.

But another problem persists. If you re-compile a substantial body of code written in C/C++, the time consuming compilation quickly becomes an obstacle. You can make only one modification per cycle, because as soon as you introduce more than one error, the errors might cancel out. Or - if you introduce a larger number of modifications - it will become cumbersome the figure out which of the modifications produced the problem or you may have even non-linear dependencies between the modifications.

Thus, error seeding as a concept is dropped.

Enter Go. The quick compilation, lean syntax, and excellent test framework out-of-the-box make error seeding suddenly a feasible strategy.

I haven't spoken about the mechanics of error seeding yet. I want to do this by way of example. In this example, I am using a Perl script to change one '==' comparison for equality with a '!=' test for inequality. I would have preferred to have a Go-only version for this text, but I don't know enough about the parser to write this error-seeder on a low-level, and Perl is always a good fit when manipulating text.

Next, I need a package as a victim. I chose a harmless package from the standard library: 'tabwriter'. It has only one source file 'tabwriter.go' and one test file 'tabwriter_test.go'. I renamed the package to 'mytabwriter' in all these two files and copied them to a temporary folder (to avoid namespace collision with the original files).

Then I wrote the Perl script 'mutator.pl'. It takes the original mytabwriter source code and creates 'mutants',  modified versions named 'mytabwriter.go.NUMBER'. Number means the n'th comparison operator was changed from '==' into '!='.

I found that tabwriter.go contains sixteen '==' operators. mutator.pl has produced 16 different versions and each has one operator patched. Then the Perl script copies these mutants back and forth and runs the 'go test' command and checks the result. Then the script renames the n'th mutation and appends either OK or FAIL to the filename. The result is the following list:

	mytabwriter.go
	mytabwriter.go.1.OK
	mytabwriter.go.2.FAIL
	mytabwriter.go.3.OK
	mytabwriter.go.4.FAIL
	mytabwriter.go.5.FAIL
	mytabwriter.go.6.FAIL
	mytabwriter.go.7.FAIL
	mytabwriter.go.8.FAIL
	mytabwriter.go.9.OK
	mytabwriter.go.10.FAIL
	mytabwriter.go.11.FAIL
	mytabwriter.go.12.FAIL
	mytabwriter.go.13.FAIL
	mytabwriter.go.14.FAIL
	mytabwriter.go.15.FAIL
	mytabwriter.go.16.FAIL

This tells me that for the modifications 1, 3 and 9, the 'go test' run did not catch the modification. I examined these particular patches to figure out, why that was the case.

CASE 1:

	diff mytabwriter.go mytabwriter.go.1.OK
	165c165
	< // if padchar == '\t', the Writer will assume ...
	---
	> // if padchar != '\t', the Writer will assume ...

This is commented out code. It has no functionality. This is not a big problem. Mutant.pl does not recognize comments, so no big deal.

CASE 3:

	diff mytabwriter.go mytabwriter.go.3.OK
	216c216
	<       if n != len(buf) && err == nil {
	---
	>       if n != len(buf) && err != nil {

This gets more interesting. There is no test case that checks 'err'!

CASE 9:

	diff mytabwriter.go mytabwriter.go.9.OK
	415c415
	<  if b.flags&StripEscape == 0 {
	---
	>  if b.flags&StripEscape != 0 { 

Another interesting case. There is obviously no test case that checks the flag StripEscape.

I originally planned to propose two test cases for these deficiencies, but I haven't looked into it yet. Since there is no check for these particular cases, I don't even know if the original code is correct!

So, using a fairly primitive technique - I could easily come up with a whole bunch of other more intricate modifications (cycle through the various comparisons, add 1 or 0 to any computation, change + to -, and so on) - I found two potential problems in the tests, perhaps even the code.

Perhaps it's possible to create a framework for Go to apply patterns of errors to packages, and produce some nicely formatted HTML output to report the problems. This would allow developers to enhance the quality and robustness of Go's tests and this would be of benefit for everyone involved. Thanks for reading. Please leave a comment.
