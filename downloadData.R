
####### Download Spam Dataset #######

if (!file.exists('CSDMC2010_SPAM')) {
  download("http://csmining.org/index.php/spam-email-datasets-.html?file=tl_files/Project_Datasets/task2/CSDMC2010_SPAM.zip", dest="dataset.zip", mode="wb") 
  unzip ("dataset.zip", exdir = "./")
  file.remove("dataset.zip")
}