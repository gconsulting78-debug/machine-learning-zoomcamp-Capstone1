import pickle

with open('model_pipeline_fitted.bin', 'rb') as f_in:
    pipeline = pickle.load(f_in)

def predict_single(teacher):
    result = pipeline.predict_proba(teacher)[0, 1]
    return float(result)

def lambda_handler(event, context):
    # print("Parameters:", event)

    teacher = event['teacher']
    prob = predict_single(teacher)

    return {
        "churn_probability": prob,
        "churn": bool(prob >= 0.5)
    }