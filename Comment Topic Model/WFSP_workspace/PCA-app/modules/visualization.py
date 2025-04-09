"""Visualization service for topic modeling results."""

from __future__ import annotations
import logging
from pathlib import Path
from typing import Any, Dict, Optional, List, Union
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import pandas as pd
from wordcloud import WordCloud
import matplotlib.pyplot as plt

from .core_types import (
    DataFrameType, ModelProtocol, StatusProtocol,
    TopicVisualizationData
)

logger = logging.getLogger(__name__)

class VisualizationService:
    """Centralized service for generating and saving visualizations."""
    
    def __init__(self, output_dir: Path):
        """Initialize visualization service with output directory."""
        self.output_dir = output_dir
        self.viz_dir = output_dir / "visualizations"
        self.viz_dir.mkdir(exist_ok=True, parents=True)
        
    async def generate_visualizations(
        self,
        model: ModelProtocol,
        data: TopicVisualizationData,
        status_manager: Optional[StatusProtocol] = None
    ) -> Dict[str, Path]:
        """Generate all visualizations for topic model results.
        
        Args:
            model: Trained topic model
            data: Visualization data containing topics and distributions
            status_manager: Optional status manager for progress updates
            
        Returns:
            Dict mapping visualization names to file paths
        """
        results = {}
        
        try:
            # Topic Distribution
            dist_fig = self.create_distribution_plot(data)
            dist_path = self.viz_dir / "topic_distribution.html"
            await self._save_plot(dist_fig, dist_path)
            results['distribution'] = dist_path
            
            # Topic Hierarchy
            if status_manager:
                status_manager.update_status("Visualization", 50, "Generating hierarchy...")
            hierarchy_fig = self.create_hierarchy_plot(data)
            hierarchy_path = self.viz_dir / "topic_hierarchy.html"
            await self._save_plot(hierarchy_fig, hierarchy_path)
            results['hierarchy'] = hierarchy_path
            
            # Word Cloud
            if status_manager:
                status_manager.update_status("Visualization", 75, "Generating word cloud...")
            wordcloud_fig = self.create_wordcloud(data.topics[0])
            wordcloud_path = self.viz_dir / "wordcloud.png"
            self._save_wordcloud(wordcloud_fig, wordcloud_path)
            results['wordcloud'] = wordcloud_path
            
            return results
            
        except Exception as e:
            logger.error(f"Error generating visualizations: {str(e)}")
            if status_manager:
                status_manager.set_error(f"Visualization error: {str(e)}")
            return results
    
    def create_distribution_plot(self, data: TopicVisualizationData) -> go.Figure:
        """Create topic distribution visualization.
        
        Args:
            data: Topic visualization data
            
        Returns:
            Plotly figure object
        """
        try:
            # Extract topic frequencies and labels
            topics = [d['label'] for d in data.distribution]
            freqs = [d['frequency'] for d in data.distribution]
            
            # Create bar plot
            fig = go.Figure(data=[
                go.Bar(
                    x=topics,
                    y=freqs,
                    text=[f"{f:.1f}%" for f in freqs],
                    textposition='auto'
                )
            ])
            
            # Update layout
            fig.update_layout(
                title="Topic Distribution",
                xaxis_title="Topics",
                yaxis_title="Document Frequency (%)",
                showlegend=False
            )
            
            return fig
            
        except Exception as e:
            logger.error(f"Error creating distribution plot: {str(e)}")
            return self._create_empty_plot("Error generating visualization")
    
    async def _save_plot(self, fig: go.Figure, path: Path) -> Optional[Path]:
        """Save plotly figure with error handling."""
        try:
            fig.write_html(str(path))
            return path
        except Exception as e:
            logger.error(f"Error saving plot: {str(e)}")
            return None
    
    def _create_empty_plot(self, message: str = "No data available") -> go.Figure:
        """Create empty plot with message."""
        fig = go.Figure()
        fig.add_annotation(
            text=message,
            xref="paper",
            yref="paper",
            x=0.5,
            y=0.5,
            showarrow=False
        )
        return fig