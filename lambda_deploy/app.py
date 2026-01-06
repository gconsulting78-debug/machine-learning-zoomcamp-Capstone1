import pickle
from typing import Literal
from pydantic import BaseModel, Field


from fastapi import FastAPI
import uvicorn



class Teacher(BaseModel):
    teacher_ethinicity: Literal["Indian", "Chinese", "Malay", "European", "Singaporean", "Dual"]
    education: Literal["PG", "UG","NG"]
    marital_status: Literal["Married", "Single","Divorced"]
    gender: Literal["Male", "Female", "Binary"]
    student_grade: Literal["Pre-K", "Primary", "Secondary"]
    subject: Literal["STEM", "English", "Language","Sports"]
    
    teacher_age: int = Field(..., ge=0)
    teacher_tenure: float = Field(..., ge=0.0)
    student_ratio: float = Field(..., ge=0.0)
    teacher_rating: int= Field(..., gt=0)
    teacher_rating_last_year: int= Field(..., gt=0)
    sick_days: int= Field(..., ge=0)

class PredictResponse(BaseModel):
    churn_probability: float
    churn: bool


app = FastAPI(title="teacher-churn-prediction")

@app.get("/health")
def health_check():
    """Simple health check endpoint for Kubernetes probes."""
    return {"status": "ok"}

with open('model_pipeline_fitted.bin', 'rb') as f_in:
    pipeline = pickle.load(f_in)


def predict_single(teacher):
    result = pipeline.predict_proba(teacher)[0, 1]
    return float(result)


@app.post("/predict")
def predict(teacher: Teacher) -> PredictResponse:
    prob = predict_single(teacher.model_dump())

    return PredictResponse(
        churn_probability=prob,
        churn=bool(prob >= 0.7)
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=9696)