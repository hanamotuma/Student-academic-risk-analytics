import pandas as pd
from sklearn.linear_model import LogisticRegression

def train_risk_model(df):
    X = df[['attendance', 'quiz_score', 'midterm_score', 'final_score']]
    y = ((X['attendance'] < 70) | ((X['quiz_score']*0.2 + X['midterm_score']*0.3 + X['final_score']*0.5) < 60)).astype(int)
    model = LogisticRegression(class_weight='balanced')
    model.fit(X, y)
    return model.predict_proba(X)[:, 1]
