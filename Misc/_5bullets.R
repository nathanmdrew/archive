#Generate 5 bullets

duties <- c("Further developed a technical report.",
          "Utilized collaborations to collect, manage, and store data.",
          "Served as a technical advisor and consultant.",
          "Conducted statistical research to further the assessment of the health status of Americans.",
          "Provided support to development of products which enhance efficiency and effectiveness.",
          "Demonstrated active collaboration with internal partners.",
          "Resolved problems in a proactive manner.",
          "Supported Center development.",
          "Cooperated with co-workers and others in meeting commitments and accomplishing assigned work on time.",
          "Provided updated information to project tracking efforts.",
          "Developed statistical programming scripts.",
          "Completed administrative requirements.")

report <- sample(x=duties, size=5, replace=F)
report
