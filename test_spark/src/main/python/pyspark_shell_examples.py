import os
  
from pyspark import SparkContext
# sc is an existing SparkContext.
from pyspark.sql import HiveContext
  
if __name__ == "__main__":
  sc = SparkContext(appName="PySpark Shell MLLib Examples")
  
  # Basic pyspark core test case
  file=sc.textFile("spark/test/README.md")
  errors = file.filter(lambda line: "scala" in line)
  # Count all the errors
  errors.count()
  # Count errors mentioning MySQL
  errors.filter(lambda line: "MySQL" in line).count()
  # Fetch the MySQL errors as an array of strings
  errors.filter(lambda line: "MySQL" in line).collect()
    
  # See: https://spark.apache.org/docs/latest/api/python/pyspark.mllib.html
  # Mllib test case
  from pyspark.mllib.regression import LabeledPoint
  from pyspark.mllib.feature import HashingTF
  from pyspark.mllib.classification import LogisticRegressionWithSGD
  
  spam = sc.textFile("spark/test/spam_sample.txt")
  normal = sc.textFile("spark/test/normal_sample.txt")
  
  # Create a HashingTF instance to map email text to vectors of 10,000 features.
  tf = HashingTF(numFeatures = 10000)
  # Each email is split into words, and each word is mapped to one feature.
  spamFeatures = spam.map(lambda email: tf.transform(email.split(" ")))
  normalFeatures = normal.map(lambda email: tf.transform(email.split(" ")))
  
  # Create LabeledPoint datasets for positive (spam) and negative (normal) examples.
  positiveExamples = spamFeatures.map(lambda features: LabeledPoint(1, features))
  negativeExamples = normalFeatures.map(lambda features: LabeledPoint(0, features))
  trainingData = positiveExamples.union(negativeExamples)
  trainingData.cache() # Cache since Logistic Regression is an iterative algorithm.
  
  # Run Logistic Regression using the SGD algorithm.
  model = LogisticRegressionWithSGD.train(trainingData)
  
  # Test on a positive example (spam) and a negative one (normal). We first apply
  # the same HashingTF feature transformation to get vectors, then apply the model.
  posTest = tf.transform("O M G GET cheap stuff by sending money to ".split(" "))
  negTest = tf.transform("Hi Dad, I started studying Spark the other ".split(" "))
  print "Prediction for positive test example: %g" % model.predict(posTest)
  print "Prediction for negative test example: %g" % model.predict(negTest)
  
  from numpy import array
  from pyspark.mllib.linalg import Vectors
  
  # Create the dense vector <1.0, 2.0, 3.0>
  denseVec1 = array([1.0, 2.0, 3.0])  # NumPy arrays can be passed directly to MLlib
  denseVec2 = Vectors.dense([1.0, 2.0, 3.0]) # .. or you can use the Vectors class
  # Create the sparse vector <1.0, 0.0, 2.0, 0.0>; the methods for this take only
  # the size of the vector (4) and the positions and values of nonzero entries.
  # These can be passed as a dictionary or as two lists of indices and values.
  sparseVec1 = Vectors.sparse(4, {0: 1.0, 2: 2.0})
  sparseVec2 = Vectors.sparse(4, [0, 2], [1.0, 2.0])
  
  from pyspark.mllib.feature import StandardScaler
  vectors = [Vectors.dense([-2.0, 5.0, 1.0]), Vectors.dense([2.0, 0.0, 1.0])]
  dataset = sc.parallelize(vectors)
  scaler = StandardScaler(withMean=True, withStd=True)
  model = scaler.fit(dataset)
  result = model.transform(dataset)
  result.collect()
  
  
  # TF-IDF Test
  from pyspark.mllib.feature import HashingTF, IDF
  # Read a set of text files as TF vectors
  rdd = sc.wholeTextFiles("spark/test/README.md").map(lambda (name, text): text.split())
  tf = HashingTF()
  tfVectors = tf.transform(rdd).cache()
  # Compute the IDF, then the TF-IDF vectors
  idf = IDF()
  idfModel = idf.fit(tfVectors)
  tfIdfVectors = idfModel.transform(tfVectors)
  
  
  
  ##############################
  #       LINEAR ALGEBRA       #
  ##############################
  # Test Linear Regression derived from least-square-fit
  # See: https://spark.apache.org/docs/latest/api/python/pyspark.mllib.html#module-pyspark.mllib.linalg
  
  from numpy import array
  from pyspark.mllib.regression import LabeledPoint
  from pyspark.mllib.linalg import SparseVector
  from pyspark.mllib.regression import LinearRegressionWithSGD
  data = [
       LabeledPoint(0.0, [0.0]),
       LabeledPoint(1.0, [1.0]),
       LabeledPoint(3.0, [2.0]),
       LabeledPoint(2.0, [3.0])
   ]
  lrm = LinearRegressionWithSGD.train(sc.parallelize(data), initialWeights=array([1.0]))
  abs(lrm.predict(array([0.0])) - 0) < 0.5
  abs(lrm.predict(array([1.0])) - 1) < 0.5
  abs(lrm.predict(SparseVector(1, {0: 1.0})) - 1) < 0.5
  data = [
       LabeledPoint(0.0, SparseVector(1, {0: 0.0})),
       LabeledPoint(1.0, SparseVector(1, {0: 1.0})),
       LabeledPoint(3.0, SparseVector(1, {0: 2.0})),
       LabeledPoint(2.0, SparseVector(1, {0: 3.0}))
   ]
  lrm = LinearRegressionWithSGD.train(sc.parallelize(data), initialWeights=array([1.0]))
  abs(lrm.predict(array([0.0])) - 0) < 0.5
  abs(lrm.predict(SparseVector(1, {0: 1.0})) - 1) < 0.5
  
  
  
  ##############################
  #       CLASSIFICATION       #
  ##############################
  # Classification - SVM Examples 
  # https://spark.apache.org/docs/latest/api/python/pyspark.mllib.html#module-pyspark.mllib.classification
  
  from pyspark.mllib.regression import LabeledPoint
  from pyspark.mllib.linalg import SparseVector
  from pyspark.mllib.classification import SVMWithSGD
  
  data = [
       LabeledPoint(0.0, [0.0]),
       LabeledPoint(1.0, [1.0]),
       LabeledPoint(1.0, [2.0]),
       LabeledPoint(1.0, [3.0])
   ]
  svm = SVMWithSGD.train(sc.parallelize(data))
  svm.predict([1.0])
  svm.predict(sc.parallelize([[1.0]])).collect()
  svm.clearThreshold()
  svm.predict(array([1.0]))
  
  sparse_data = [
       LabeledPoint(0.0, SparseVector(2, {0: -1.0})),
       LabeledPoint(1.0, SparseVector(2, {1: 1.0})),
       LabeledPoint(0.0, SparseVector(2, {0: 0.0})),
       LabeledPoint(1.0, SparseVector(2, {1: 2.0}))
   ]
  svm = SVMWithSGD.train(sc.parallelize(sparse_data))
  svm.predict(SparseVector(2, {1: 1.0}))
  svm.predict(SparseVector(2, {0: -1.0}))
  
  
  # Classification - Naive Bayes Examples
  # See: https://spark.apache.org/docs/latest/api/python/pyspark.mllib.html#module-pyspark.mllib.classification
  
  from pyspark.mllib.regression import LabeledPoint
  from pyspark.mllib.linalg import SparseVector
  from pyspark.mllib.classification import NaiveBayes
  data = [
       LabeledPoint(0.0, [0.0, 0.0]),
       LabeledPoint(0.0, [0.0, 1.0]),
       LabeledPoint(1.0, [1.0, 0.0]),
   ]
  model = NaiveBayes.train(sc.parallelize(data))
  model.predict(array([0.0, 1.0]))
  model.predict(array([1.0, 0.0]))
  model.predict(sc.parallelize([[1.0, 0.0]])).collect()
  sparse_data = [
       LabeledPoint(0.0, SparseVector(2, {1: 0.0})),
       LabeledPoint(0.0, SparseVector(2, {1: 1.0})),
       LabeledPoint(1.0, SparseVector(2, {0: 1.0}))
   ]
  model = NaiveBayes.train(sc.parallelize(sparse_data))
  model.predict(SparseVector(2, {1: 1.0}))
  model.predict(SparseVector(2, {0: 1.0}))
  
  
  
  ##############################
  #         CLUSTERING         #
  ##############################
  # Clustering - KMeans Example
  # See: https://spark.apache.org/docs/latest/api/python/pyspark.mllib.html#module-pyspark.mllib.clustering
  
  from numpy import array
  from pyspark.mllib.linalg import SparseVector
  from pyspark.mllib.clustering import KMeans
  data = array([0.0,0.0, 1.0,1.0, 9.0,8.0, 8.0,9.0]).reshape(4, 2)
  model = KMeans.train(
       sc.parallelize(data), 2, maxIterations=10, runs=30, initializationMode="random")
  model.predict(array([0.0, 0.0])) == model.predict(array([1.0, 1.0]))
  model.predict(array([8.0, 9.0])) == model.predict(array([9.0, 8.0]))
  model = KMeans.train(sc.parallelize(data), 2)
  sparse_data = [
       SparseVector(3, {1: 1.0}),
       SparseVector(3, {1: 1.1}),
       SparseVector(3, {2: 1.0}),
       SparseVector(3, {2: 1.1})
   ]
  model = KMeans.train(sc.parallelize(sparse_data), 2, initializationMode="k-means||")
  model.predict(array([0., 1., 0.])) == model.predict(array([0, 1.1, 0.]))
  model.predict(array([0., 0., 1.])) == model.predict(array([0, 0, 1.1]))
  model.predict(sparse_data[0]) == model.predict(sparse_data[1])
  model.predict(sparse_data[2]) == model.predict(sparse_data[3])
  type(model.clusterCenters)
  
  # Clustering - GaussianMixture
  # See: https://spark.apache.org/docs/latest/api/python/pyspark.mllib.html#module-pyspark.mllib.clustering
  
  from numpy import array
  from pyspark.mllib.clustering import GaussianMixture
  clusterdata_1 =  sc.parallelize(array([-0.1,-0.05,-0.01,-0.1,
                                           0.9,0.8,0.75,0.935,
                                          -0.83,-0.68,-0.91,-0.76 ]).reshape(6, 2))
  model = GaussianMixture.train(clusterdata_1, 3, convergenceTol=0.0001,
                                   maxIterations=50, seed=10)
  labels = model.predict(clusterdata_1).collect()
  labels[0]==labels[1]
  labels[1]==labels[2]
  labels[4]==labels[5]
  clusterdata_2 =  sc.parallelize(array([-5.1971, -2.5359, -3.8220,
                                          -5.2211, -5.0602,  4.7118,
                                           6.8989, 3.4592,  4.6322,
                                           5.7048,  4.6567, 5.5026,
                                           4.5605,  5.2043,  6.2734]).reshape(5, 3))
  model = GaussianMixture.train(clusterdata_2, 2, convergenceTol=0.0001,
                                   maxIterations=150, seed=10)
  labels = model.predict(clusterdata_2).collect()
  labels[0]==labels[1]==labels[2]
  labels[3]==labels[4]
  
  
  
  ##############################
  #      RECOMMENDATION        #
  ##############################
  # Recommendation - ALS Example
  # See: https://spark.apache.org/docs/latest/api/python/pyspark.mllib.html#module-pyspark.mllib.recommendation
  
  from pyspark.mllib.recommendation import ALS
  r1 = (1, 1, 1.0)
  r2 = (1, 2, 2.0)
  r3 = (2, 1, 2.0)
  ratings = sc.parallelize([r1, r2, r3])
  model = ALS.trainImplicit(ratings, 1, seed=10)
  model.predict(2, 2)
  testset = sc.parallelize([(1, 2), (1, 1)])
  model = ALS.train(ratings, 2, seed=0)
  model.predictAll(testset).collect()
  model = ALS.train(ratings, 4, seed=10)
  model.userFeatures().collect()
  first_user = model.userFeatures().take(1)[0]
  latents = first_user[1]
  len(latents) == 4
  model.productFeatures().collect()
  first_product = model.productFeatures().take(1)[0]
  latents = first_product[1]
  len(latents) == 4
  model = ALS.train(ratings, 1, nonnegative=True, seed=10)
  model.predict(2,2)
  model = ALS.trainImplicit(ratings, 1, nonnegative=True, seed=10)
  model.predict(2,2)
  
  sc.stop() 
  
