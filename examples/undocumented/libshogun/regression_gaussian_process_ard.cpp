/*
 * This software is distributed under BSD 3-clause license (see LICENSE file).
 *
 * Authors: Jacob Walker, Sergey Lisitsyn, Roman Votyakov, Viktor Gal, 
 *          Bjoern Esser, Pan Deng
 */

#include <shogun/lib/config.h>

// temporally disabled, since API was changed
#if defined(HAVE_NLOPT) && 0

#include <shogun/labels/RegressionLabels.h>
#include <shogun/features/DenseFeatures.h>
#include <shogun/kernel/LinearARDKernel.h>
#include <shogun/mathematics/Math.h>
#include <shogun/machine/gp/ExactInferenceMethod.h>
#include <shogun/machine/gp/GaussianLikelihood.h>
#include <shogun/machine/gp/ZeroMean.h>
#include <shogun/regression/GaussianProcessRegression.h>
#include <shogun/evaluation/GradientEvaluation.h>
#include <shogun/modelselection/GradientModelSelection.h>
#include <shogun/modelselection/ModelSelectionParameters.h>
#include <shogun/modelselection/ParameterCombination.h>
#include <shogun/evaluation/GradientCriterion.h>

using namespace shogun;

int32_t num_vectors=4;
int32_t dim_vectors=3;

void build_matrices(SGMatrix<float64_t>& test, SGMatrix<float64_t>& train,
		    CRegressionLabels* labels)
{
	/*Fill Matrices with random nonsense*/
	train[0] = -1;
	train[1] = -1;
	train[2] = -1;
	train[3] = 1;
	train[4] = 1;
	train[5] = 1;
	train[6] = -10;
	train[7] = -10;
	train[8] = -10;
	train[9] = 3;
	train[10] = 2;
	train[11] = 1;

	for (int32_t i=0; i<num_vectors*dim_vectors; i++)
	    test[i]=i*sin(i)*.96;

	/* create labels, two classes */
	for (index_t i=0; i<num_vectors; ++i)
	{
		if(i%2 == 0) labels->set_label(i, 1);
		else labels->set_label(i, -1);
	}
}

CModelSelectionParameters* build_tree(CInferenceMethod* inf,
				      CLikelihoodModel* lik, CKernel* kernel,
				      SGVector<float64_t>& weights)
{
	CModelSelectionParameters* root=new CModelSelectionParameters();

	CModelSelectionParameters* c1 =
			new CModelSelectionParameters("inference_method", inf);
	root->append_child(c1);

	CModelSelectionParameters* c2 =
			new CModelSelectionParameters("likelihood_model", lik);
	c1->append_child(c2);

	CModelSelectionParameters* c3=new CModelSelectionParameters("sigma");
	c2->append_child(c3);
	c3->build_values(1.0, 4.0, R_LINEAR);

        CModelSelectionParameters* c4=new CModelSelectionParameters("scale");
        c1->append_child(c4);
        c4->build_values(1.0, 1.0, R_LINEAR);

	CModelSelectionParameters* c5 =
			new CModelSelectionParameters("kernel", kernel);
	c1->append_child(c5);

	CModelSelectionParameters* c6 =
			new CModelSelectionParameters("weights");
	c5->append_child(c6);
	c6->build_values_sgvector(0.001, 4.0, R_LINEAR, &weights);

	return root;
}

int main(int argc, char **argv)
{
	/* create some data and labels */
	SGMatrix<float64_t> matrix =
			SGMatrix<float64_t>(dim_vectors, num_vectors);

	SGVector<float64_t> weights(dim_vectors);

	SGMatrix<float64_t> matrix2 =
			SGMatrix<float64_t>(dim_vectors, num_vectors);

	CRegressionLabels* labels=new CRegressionLabels(num_vectors);

	build_matrices(matrix2, matrix, labels);

	/* create training features */
	CDenseFeatures<float64_t>* features=new CDenseFeatures<float64_t> ();
	features->set_feature_matrix(matrix);

	/* create testing features */
	CDenseFeatures<float64_t>* features2=new CDenseFeatures<float64_t> ();
	features2->set_feature_matrix(matrix2);

	SG_REF(features);
	SG_REF(features2);

	SG_REF(labels);

	/*Allocate our Kernel*/
	CLinearARDKernel* test_kernel = new CLinearARDKernel(10);

	test_kernel->init(features, features);

	/*Allocate our mean function*/
	CZeroMean* mean = new CZeroMean();

	/*Allocate our likelihood function*/
	CGaussianLikelihood* lik = new CGaussianLikelihood();

	/*Allocate our inference method*/
	CExactInferenceMethod* inf =
			new CExactInferenceMethod(test_kernel,
						  features, mean, labels, lik);

	SG_REF(inf);

	/*Finally use these to allocate the Gaussian Process Object*/
	CGaussianProcessRegression* gp =
			new CGaussianProcessRegression(inf);

	SG_REF(gp);

	/*Build the parameter tree for model selection*/
	CModelSelectionParameters* root = build_tree(inf, lik, test_kernel,
						     weights);

	/*Criterion for gradient search*/
	CGradientCriterion* crit = new CGradientCriterion();

	/*This will evaluate our inference method for its derivatives*/
	CGradientEvaluation* grad=new CGradientEvaluation(gp, features, labels,
			crit);

	grad->set_function(inf);

	gp->print_modsel_params();

	root->print_tree();

	/* handles all of the above structures in memory */
	CGradientModelSelection* grad_search=new CGradientModelSelection(
			root, grad);

	/* set autolocking to false to get rid of warnings */
	grad->set_autolock(false);

	/*Search for best parameters*/
	CParameterCombination* best_combination=grad_search->select_model(true);

	/*Output all the results and information*/
	if (best_combination)
	{
		SG_SPRINT("best parameter(s):\n");
		best_combination->print_tree();

		best_combination->apply_to_machine(gp);
	}

	CGradientResult* result=(CGradientResult*)grad->evaluate();

	if(result->get_result_type() != GRADIENTEVALUATION_RESULT)
		SG_SERROR("Evaluation result not a GradientEvaluationResult!");

	result->print_result();

	SGVector<float64_t> alpha = inf->get_alpha();
	SGVector<float64_t> labe = labels->get_labels();
	SGVector<float64_t> diagonal = inf->get_diagonal_vector();
	SGMatrix<float64_t> cholesky = inf->get_cholesky();
	CRegressionLabels* predictions=gp->apply_regression(features);
	SGVector<float64_t> variance_vector=gp->get_variance_vector(features);

	alpha.display_vector("Alpha Vector");
	labe.display_vector("Labels");
	diagonal.display_vector("sW Matrix");
	variance_vector.display_vector("Predicted Variances");
	predictions->get_labels().display_vector("Mean Predictions");
	cholesky.display_matrix("Cholesky Matrix L");
	matrix.display_matrix("Training Features");
	matrix2.display_matrix("Testing Features");

	/*free memory*/
	SG_UNREF(features);
	SG_UNREF(features2);
	SG_UNREF(predictions);
	SG_UNREF(labels);
	SG_UNREF(inf);
	SG_UNREF(gp);
	SG_UNREF(grad_search);
	SG_UNREF(best_combination);
	SG_UNREF(result);

	return 0;
}
#else
int main(int argc, char **argv)
{
	return 0;
}
#endif
