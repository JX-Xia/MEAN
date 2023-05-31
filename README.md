## Source code of the paper "The Doctrine of MEAN: Realizing Deduplication Storage at Unreliable Edge"

#### We have released the main source code of MEAN and placed several out-of-the-box test examples for readers to understand and help improve MEAN and develop it further to real systems.

#### The files "test_Scenario1.m" and "test_Scenario2and3.m" are two test examples, which can calculate the placement strategy of edge servers based on the information in the "datasets" folder, and the results are output to the "results" folder. 

#### To evaluate the calculation results, we have added an out-of-the-box test case that can evaluate the hit ratios of comparison methods. 
#### To run the example, you need to run "test_Scenario2and3.m" first, and when you're done, you'll find the output files in the results folder. 
#### Then, you can run "genTestFiles.py" to generate some server failure modes and file requests based on file popularity. 
#### The results are output to the "tmp" folder. 
#### Finally, you can run the "test_HitRatio.py"  to test the hit ratio of these methods. 
#### The result evaluation of "test_Scenario1.m" can be achieved by modifying the relevant parameters in the codes, which is marked in releant files.
#### We have also added the codes of the cloud and edge servers. These released codes can be deployed on real-world servers to evaluate the retrieval performance like delays and throughput.

#### The speed of the codes still needs to be optimized, which will be improved in the future.

#### Detailed in the paper "The Doctrine of MEAN: Realizing Deduplication Storage at Unreliable Edge".
