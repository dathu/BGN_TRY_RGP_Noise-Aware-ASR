import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

cm = np.array([
    [4375,  77,  44,   4],
    [ 229, 4250, 18,   3],
    [ 244,  63, 4191,  2],
    [ 234,  47,   9, 4210]
])

labels = ['Airport', 'Babble', 'Restaurant', 'Station']

# Remove Restaurant (index = 2)
cm_reduced = np.delete(cm, 2, axis=0)  # remove row
cm_reduced = np.delete(cm_reduced, 2, axis=1)  # remove column

new_labels = ['Airport', 'Babble', 'Station']

plt.figure(figsize=(6,5))
sns.heatmap(cm_reduced, annot=True, fmt='d', cmap='Blues',
            xticklabels=new_labels,
            yticklabels=new_labels)
plt.xlabel('Predicted Labels')
plt.ylabel('True Labels')
plt.title('Confusion Matrix (Restaurant Removed)')
plt.show()
