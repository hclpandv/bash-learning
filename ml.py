from sklearn import tree

my_crypto_string = "TA%aqi}YK7SqbK;"
#features = [[140, "smooth"],[130, "smooth"],[150, "bumpy"], [170, "bumpy"]]
features = [[140, 1],[130, 1],[150, 0], [170, 0]]
#labels = ["apple", "apple", "orange", "orange"]
labels = [0, 0, 1, 1]

clf = tree.DecisionTreeClassifier()

clf = clf.fit(features, labels)

print clf.predict([[80, 1]])


