## 🎯 Introduction: Project Motivation

This project applies machine learning principles to predict **teacher churn** for a pre-high school chain operator. High teacher turnover was impacting student scores and parent satisfaction, making this a critical business problem. The solution is a trained **XGBoost classification model** (best AUC: 0.8973) deployed as a **containerized AWS Lambda function** for serverless prediction inference.

---

## ➡️ 1. Repository Setup & Cloning

To begin evaluating the project, use the following commands to clone the repository and navigate into the project directory.

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/gconsulting78-debug/machine-learning-zoomcamp-Capstone1.git](https://github.com/gconsulting78-debug/machine-learning-zoomcamp-Capstone1.git)
    ```
    *(Note: Please ensure this link points to your final, correct GitHub repository URL.)*

2.  **Navigate to the Directory:**
    ```bash
    cd Capstone1
    ```
---

## 💾 2. Critical Prerequisites and Asset Downloads

### Required Assets (Manual Download Required) ⚠️

Due to Git storage limits, the trained model and data are hosted externally. **You must download these two files and place them in the root 
directory of this repository (`Capstone1/`) before running the deployment script.**

| Asset | Description | Download Link |
| :--- | :--- | :--- |
| **`model_pipeline_fitted.bin`** | The final, trained XGBoost model and pipeline artifact, which is loaded by `app.py`. | 
[https://drive.google.com/file/d/19uyMwRnf8eX7hljMdKr4D3SB-0ko72C6/view?usp=drive_link](https://drive.google.com/file/d/19uyMwRnf8eX7hljMdKr4D3SB-0ko72C6/view?usp=drive_link) 
|
| **`Teacher-Churn_Mid_Term_Project1.csv`** | The original dataset used for model training/replication. | 
[https://drive.google.com/file/d/1JD71JjUIb9LkHHFnwDVQmYqjJoYzmRa0/view?usp=drive_link](https://drive.google.com/file/d/1JD71JjUIb9LkHHFnwDVQmYqjJoYzmRa0/view?usp=drive_link) 
|

### Environment Setup

Ensure you have the following installed and configured:
* **AWS CLI:** Configured with credentials for the target AWS Account and Region (`ap-southeast-2`).
* **Docker:** Running on your machine.
* **`jq`:** Command-line JSON processor.

---

## 🚀 3. Deployment Steps to AWS Lambda

This assumes the necessary IAM Role (e.g., `teacher-churn-prediction-role-me7tbz9s`) has been created with permissions for ECR and Lambda 
execution.

1.  **Navigate to the Deployment Directory:**
    ```bash
    cd lambda_deploy
    ```

2.  **Run the Deployment Script:**
    This script logs into ECR, builds the Docker image, pushes the image, and creates the Lambda function.
    ```bash
    ./deploy.sh
    ```

3.  **Wait for Active Status:**
    The function will initially be in a `Pending` state. Wait 1-2 minutes and confirm it is ready:
    ```bash
    aws lambda get-function --function-name teacher-churn-prediction-docker --query 'Configuration.{State:State, 
LastUpdateStatus:LastUpdateStatus}'
    # Expected output: {"State": "Active", "LastUpdateStatus": "Successful"}
    ```

---

## 🧪 4. Testing the Live Prediction Endpoint

Once the function state is `Active`, you can verify the successful execution by invoking it with a test payload.

1.  **Create the Test Payload File (`test_payload.json`):**
    ```json
    {
      "teacher": {
        "teacher_ethnicity": "Chinese",
        "teacher_age": 24,
        "teacher_tenure": 9.0,
        "student_ratio": 27.0,
        "education": "NG",
        "teacher_rating": 5,
        "teacher_rating_last_year": 3,
        "sick_days": 10,
        "marital_status": "Single",
        "gender": "Female",
        "student_grade": "Primary",
        "subject": "English"
      }
    }
    ```

2.  **Invoke the Function and Get the Result:**
    ```bash
    aws lambda invoke \
      --function-name teacher-churn-prediction-docker \
      --cli-binary-format raw-in-base64-out \
      --payload file://test_payload.json \
      response.json
    ```

**Expected Result:** The `response.json` file should contain the following output:

```json
{
  "churn_probability": 0.08159767836332321,
  "churn": "False"
}.

---

## 📊 5. Modeling and EDA Summary

### Data Attributes

Various factors were considered, including: Teacher Ethnicity, Teacher Age, Teacher Tenure, Student Ratio, Education (NG/UG/PG), Teacher Rating, 
Sick Days, Marital Status, Gender, Student Grade, and Subject.

### Key EDA Results

* **Numerical:** Highest ROC-AUC score found for `student_ratio`.
* **Categorical:** Highest Mutual Information Score found for `education`.

### Modeling Choice

Four classification models were tested (Logistic Regression, Decision Tree, Random Forest, and XGBoost). The **XGBoost Classifier** was chosen 
for final deployment due to achieving the best performance (AUC of **0.8973**).
